using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Verse }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Fortnite.com/FortPlayerUtilities }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }

arena_controller := class(creative_device):
    @editable:
        ToolTip := LobbyMenuManagerInfo
    LobbyMenuManager : lobby_menu_manager = lobby_menu_manager{}

    @editable:
        ToolTip := InitialLoadingDurationInfo
    InitialLoadingDuration : float = 4.0
    @editable DamageDevice : health_powerup_device = health_powerup_device{}

    var Player1 : ?agent = false
    var Player2 : ?agent = false
    var Player1Score : int = 0
    var Player2Score : int = 0
    var CurrentRound : int = 0
    var MatchSettings : match_settings = match_settings{}
    var BoundMap : ?arena_map = false
    var LobbyTP : ?teleporter_device = false

    var LoadoutMgrRef : ?loadout_manager = false
    var StatsMgrRef : ?stats_manager = false
    var MapMgrRef : ?map_manager = false
    var LobbyMenuManagerRef : ?lobby_menu_manager = false

    var Player1HUD : ?UI.PlayerInfoWidget = false
    var Player2HUD : ?UI.PlayerInfoWidget = false

    var MatchOver : logic = false
    var MatchCancelled : logic = false
    var RoundOver : logic = false
    var EliminationHandled : logic = false
    var OvertimeActive : logic = false
    var CurrentMatchGeneration : int = 0
    var ConsecutiveDraws : int = 0
    var MatchSubscriptions : []cancelable = array{}
    var Player1Won : logic = false
    var RoundResultVisible : logic = false

    GetLobbyMenuManager() : lobby_menu_manager =
        if (Ref := LobbyMenuManagerRef?) then return Ref
        return LobbyMenuManager

    InitMatch<public>(Competitor1 : agent, Competitor2 : agent, Settings : match_settings, Map : arena_map, Lobby : teleporter_device, 
    LoadoutMgr : loadout_manager, StatsMgr : stats_manager, MapMgr : map_manager, MenuMgr : lobby_menu_manager) : void =

        set CurrentMatchGeneration += 1
        LocalGen := CurrentMatchGeneration

        set Player1 = option { Competitor1 }
        set Player2 = option { Competitor2 }
        set Player1Score = 0
        set Player2Score = 0
        set CurrentRound = 0
        set MatchSettings = Settings
        set BoundMap = option { Map }
        set LobbyTP = option { Lobby }
        set LoadoutMgrRef = option { LoadoutMgr }
        set StatsMgrRef = option { StatsMgr }
        set MapMgrRef = option { MapMgr }
        set LobbyMenuManagerRef = option { MenuMgr }
        set MatchOver = false
        set MatchCancelled = false
        set RoundOver = false
        set EliminationHandled = false

        Print("[ArenaController] InitMatch (Gen {LocalGen}) starting in \"{Map.General.MapName}\".")

        ActiveMenuMgr := GetLobbyMenuManager()

        # Snapshot contract states prior to combat for deterministic AAR delta calculations
        ActiveMenuMgr.ContractManager.SnapshotMatchPreState(Competitor1)
        ActiveMenuMgr.ContractManager.SnapshotMatchPreState(Competitor2)

        # Hide lobby menu and enable combat controls
        ActiveMenuMgr.HideLobbyMenuForPlayer(Competitor1)
        ActiveMenuMgr.HideLobbyMenuForPlayer(Competitor2)

        MapMgr.ActivateMap(Map)
        ShowMatchHUD(Competitor1, Competitor2, Map)
        if (HUD1 := Player1HUD?):
            set HUD1.RoundStartAnim = true
        if (HUD2 := Player2HUD?):
            set HUD2.RoundStartAnim = true
        spawn { MatchLoop(Map, LocalGen) }

    OnBegin<override>()<suspends> : void = GetPlayspace().PlayerRemovedEvent().Subscribe(OnPlayerRemoved)

    HandlePlayerLeft(LeavingAgent : agent) : void =
        if (MatchOver? or MatchCancelled?) then return
        GetLobbyMenuManager().HandlePlayerDisconnected(LeavingAgent)
        HandlePlayerAbandonment(CurrentMatchGeneration)

    OnPlayerRemoved(Player : player) : void =
        if (MatchOver? or MatchCancelled?) then return
        if (P1 := Player1?, P1Player := player[P1], P1Player = Player):
            HandlePlayerLeft(P1)
        else if (P2 := Player2?, P2Player := player[P2], P2Player = Player):
            HandlePlayerLeft(P2)

    ShowMatchHUD(Competitor1 : agent, Competitor2 : agent, Map : arena_map) : void =
        P1Name := AgentNameMessage(Competitor1)
        P2Name := AgentNameMessage(Competitor2)
        ArenaMsg := StringToMessage(Map.General.MapName)
        InitialTimer := StringToMessage(FormatTime(MatchSettings.RoundTimeLimit))

        if (P1Plr := player[Competitor1], P1UI := GetPlayerUI[P1Plr]):
            HUD1 := UI.PlayerInfoWidget{}
            set HUD1.Player1Name = P1Name
            set HUD1.Player2Name = P2Name
            set HUD1.ArenaName = ArenaMsg
            set HUD1.Player1Score = Player1Score
            set HUD1.Player2Score = Player2Score
            set HUD1.RoundTimer = InitialTimer
            set HUD1.ArenaThumbnail = Map.General.LargeThumbnail
            set HUD1.IsPlayer1 = true
            set HUD1.ShowLoadingScreen = true
            set HUD1.RoundStartAnim = false
            set HUD1.ShowDraw = false
            set HUD1.Player1ScoreAnim = false
            set HUD1.Player2ScoreAnim = false
            set HUD1.RoundResultAnim = false
            set HUD1.ShowMatchWinner = false
            set HUD1.ShowMatchLoser = false
            set HUD1.ShowMatchCancelled = false
            P1UI.AddWidget(HUD1, player_ui_slot{ ZOrder := 10, InputMode := ui_input_mode.None })
            set Player1HUD = option { HUD1 }

        if (P2Plr := player[Competitor2], P2UI := GetPlayerUI[P2Plr]):
            HUD2 := UI.PlayerInfoWidget{}
            set HUD2.Player1Name = P1Name
            set HUD2.Player2Name = P2Name
            set HUD2.ArenaName = ArenaMsg
            set HUD2.Player1Score = Player1Score
            set HUD2.Player2Score = Player2Score
            set HUD2.RoundTimer = InitialTimer
            set HUD2.ArenaThumbnail = Map.General.LargeThumbnail
            set HUD2.IsPlayer1 = false
            set HUD2.ShowLoadingScreen = true
            set HUD2.ShowDraw = false
            set HUD2.RoundStartAnim = false
            set HUD2.Player1ScoreAnim = false
            set HUD2.Player2ScoreAnim = false
            set HUD2.RoundResultAnim = false
            set HUD2.ShowMatchWinner = false
            set HUD2.ShowMatchLoser = false
            set HUD2.ShowMatchCancelled = false
            P2UI.AddWidget(HUD2, player_ui_slot{ ZOrder := 10, InputMode := ui_input_mode.None })
            set Player2HUD = option { HUD2 }

    UpdateHUDScores() : void =
        if (HUD1 := Player1HUD?):
            set HUD1.Player1Score = Player1Score
            set HUD1.Player2Score = Player2Score
        if (HUD2 := Player2HUD?):
            set HUD2.Player1Score = Player1Score
            set HUD2.Player2Score = Player2Score

    UpdateHUDTimer(TimeRemaining : float) : void =
        TimerMsg := StringToMessage(FormatTime(TimeRemaining))
        if (HUD1 := Player1HUD?):
            set HUD1.RoundTimer = TimerMsg
        if (HUD2 := Player2HUD?):
            set HUD2.RoundTimer = TimerMsg

    UpdateHUDLoadingScreen(ShouldShow : logic) : void =
        if (HUD1 := Player1HUD?):
            set HUD1.ShowLoadingScreen = ShouldShow
        if (HUD2 := Player2HUD?):
            set HUD2.ShowLoadingScreen = ShouldShow

    HideMatchHUD() : void =
        if (P1 := Player1?, P1Plr := player[P1], P1UI := GetPlayerUI[P1Plr], HUD1 := Player1HUD?):
            P1UI.RemoveWidget(HUD1)
        set Player1HUD = false
        if (P2 := Player2?, P2Plr := player[P2], P2UI := GetPlayerUI[P2Plr], HUD2 := Player2HUD?):
            P2UI.RemoveWidget(HUD2)
        set Player2HUD = false

    SetPlayersVulnerability(Vulnerable : logic) : void =
        if (P1 := Player1?, FC1 := P1.GetFortCharacter[], FC1.IsActive[], FC1.GetHealth() > 0.0):
            FC1.SetVulnerability(Vulnerable)
        if (P2 := Player2?, FC2 := P2.GetFortCharacter[], FC2.IsActive[], FC2.GetHealth() > 0.0):
            FC2.SetVulnerability(Vulnerable)

    TeleportPlayerSafely(Agent : agent, TeleporterDevice : teleporter_device)<suspends> : void =
        SpawnTrans := TeleporterDevice.GetTransform()
        SafeElevation := vector3{ X := 0.0, Y := 0.0, Z := 50.0 }
        SafePos := SpawnTrans.Translation + SafeElevation

        var Teleported : logic = false
        var Attempts : int = 0
        loop:
            if (Teleported? or Attempts >= 20) then break
            set Attempts += 1

            if (FC := Agent.GetFortCharacter[], FC.IsActive[]):
                if (FC.TeleportTo[SafePos, SpawnTrans.Rotation]):
                    set Teleported = true
                    break
                else if (FC.TeleportTo[SpawnTrans.Translation, SpawnTrans.Rotation]):
                    set Teleported = true
                    break

            if (not Teleported?):
                TeleporterDevice.Teleport(Agent)

            Sleep(0.1)

            if (FC := Agent.GetFortCharacter[], FC.IsActive[]):
                CharPos := FC.GetTransform().Translation
                if (Distance(CharPos, SpawnTrans.Translation) < 350.0):
                    set Teleported = true
                    break

    MatchLoop(Map : arena_map, Gen : int)<suspends> : void =
        loop:
            if (MatchOver? or MatchCancelled? or Gen <> CurrentMatchGeneration) then break

            if (P1 := Player1?, P2 := Player2?, P1Plr := player[P1], P2Plr := player[P2], P1Plr.IsActive[], P2Plr.IsActive[], LoadoutMgr := LoadoutMgrRef?):
                set CurrentRound += 1
                set RoundOver = false
                set EliminationHandled = false
                set OvertimeActive = false
                set RoundResultVisible = false
                set Player1Won = false

                Print("[ArenaController] Starting Round {CurrentRound} in \"{Map.General.MapName}\". Score: {Player1Score} - {Player2Score}.")
                UpdateHUDScores()
                UpdateHUDTimer(MatchSettings.RoundTimeLimit)
                UpdateHUDMatchState()
                ResetArena(Map)

                # --- STEP 1: AWAIT LIVING CHARACTER PAWNS (Non-blocking retry loop) ---
                var ActiveFC1 : ?fort_character = false
                var ActiveFC2 : ?fort_character = false

                var AwaitTicks : int = 0
                loop:
                    if (ActiveFC1? and ActiveFC2?):
                        break
                    if (AwaitTicks >= 150): # 15 seconds max wait for respawn
                        break
                    set AwaitTicks += 1

                    if (not ActiveFC1?):
                        if (FC1 := P1.GetFortCharacter[], FC1.IsActive[], FC1.GetHealth() > 0.0):
                            set ActiveFC1 = option { FC1 }

                    if (not ActiveFC2?):
                        if (FC2 := P2.GetFortCharacter[], FC2.IsActive[], FC2.GetHealth() > 0.0):
                            set ActiveFC2 = option { FC2 }

                    Sleep(0.1)

                if (FC1 := ActiveFC1?, FC2 := ActiveFC2?):
                    # --- STEP 2: TELEPORT COMPETITORS SAFELY ---
                    TeleportPlayerSafely(P1, Map.Player1Spawn)
                    TeleportPlayerSafely(P2, Map.Player2Spawn)

                    Sleep(0.15)
                    if (MatchOver? or MatchCancelled? or Gen <> CurrentMatchGeneration) then break

                    SetPlayersVulnerability(false)

                    # --- STEP 3: HEALTH RESET & DETERMINISTIC SUBSCRIPTIONS ---
                    FC1.SetHealth(FC1.GetMaxHealth())
                    FC1.SetShield(FC1.GetMaxShield())
                    FC2.SetHealth(FC2.GetMaxHealth())
                    FC2.SetShield(FC2.GetMaxShield())

                    ClearSubscriptions()
                    set MatchSubscriptions += array { FC1.EliminatedEvent().Subscribe(OnPlayerEliminated) }
                    set MatchSubscriptions += array { FC2.EliminatedEvent().Subscribe(OnPlayerEliminated) }

                    # --- STEP 4: WEAPON GRANT & BACKPACK ATTACHMENTS ---
                    LoadoutMgr.GrantMatchLoadout(P1, P2, Map.LoadoutIndex)
                    ActiveMenuMgr := GetLobbyMenuManager()
                    ActiveMenuMgr.CustomizationManager.ApplyEquippedBackpackVfx(P1)
                    ActiveMenuMgr.CustomizationManager.ApplyEquippedBackpackVfx(P2)

                    # --- STEP 5: LOADING SCREEN (Round 1 Only) ---
                    if (CurrentRound = 1):
                        UpdateHUDLoadingScreen(true)
                        Sleep(InitialLoadingDuration)
                        if (MatchOver? or MatchCancelled? or Gen <> CurrentMatchGeneration) then break
                        UpdateHUDLoadingScreen(false)
                    else:
                        UpdateHUDLoadingScreen(false)

                    # --- STEP 6: PRE-ROUND STASIS COUNTDOWN ---
                    PutPlayersInStasis()
                    SetPlayersVulnerability(false)

                    var StasisRemaining : float = MatchSettings.RoundStasisDuration
                    UpdateHUDStasisCountdown(StasisRemaining, true)

                    loop:
                        if (StasisRemaining <= 0.0) then break
                        PutPlayersInStasis()
                        Sleep(1.0)
                        set StasisRemaining -= 1.0
                        if (StasisRemaining > 0.0):
                            UpdateHUDStasisCountdown(StasisRemaining, true)

                    # --- STEP 7: RELEASE STASIS & UNLOCK VULNERABILITY ---
                    UpdateHUDStasisCountdown(0.0, false)
                    RemovePlayersFromStasis()
                    SetPlayersVulnerability(true)

                    # --- STEP 8: ACTIVE ROUND COMBAT LOOP ---
                    UpdateHUDTimer(MatchSettings.RoundTimeLimit)
                    var TimeRemaining : float = MatchSettings.RoundTimeLimit

                    loop:
                        if (RoundOver? or MatchOver? or MatchCancelled? or Gen <> CurrentMatchGeneration) then break
                        if (TimeRemaining <= 0.0):
                            UpdateHUDTimer(0.0)
                            HandleRoundTimeout()
                            break

                        # Fail-safe state check: if a character reached 0 health
                        if (FC1.GetHealth() <= 0.0 or not FC1.IsActive[]):
                            HandleEliminationSafely(P1, P2)
                            break
                        if (FC2.GetHealth() <= 0.0 or not FC2.IsActive[]):
                            HandleEliminationSafely(P2, P1)
                            break

                        UpdateHUDTimer(TimeRemaining)
                        Sleep(0.5)
                        set TimeRemaining -= 0.5

                    ClearSubscriptions()

                    # Freeze and protect living players during celebration delay
                    PutPlayersInStasis()
                    SetPlayersVulnerability(false)

                    Sleep(MatchSettings.InterRoundDelay)

                    # Release stasis so eliminated players are free to respawn
                    RemovePlayersFromStasis()
                else:
                    Print("[ArenaController] ERROR: Failed to instantiate character pawns for competitors.")
                    HandlePlayerAbandonment(Gen)
                    break
            else:
                HandlePlayerAbandonment(Gen)
                break
        EndMatch(Map, Gen)

    ClearSubscriptions() : void =
        for (Sub : MatchSubscriptions) do Sub.Cancel()
        set MatchSubscriptions = array{}

    UpdateHUDStasisCountdown(TimeRemaining : float, Trigger : logic) : void =
        CountdownMsg := StringToMessage(FormatTime(TimeRemaining))
        if (HUD1 := Player1HUD?):
            set HUD1.StasisCountdown = CountdownMsg
            set HUD1.StasisCountdownAnim = Trigger
            set HUD1.ShowOvertime = false
        if (HUD2 := Player2HUD?):
            set HUD2.StasisCountdown = CountdownMsg
            set HUD2.StasisCountdownAnim = Trigger
            set HUD2.ShowOvertime = false

    HandleEliminationSafely(VictimAgent : agent, KillerAgent : agent) : void =
        if (RoundOver? or EliminationHandled?) then return
        set EliminationHandled = true
        set RoundOver = true
        set OvertimeActive = false

        SetPlayersVulnerability(false)

        if (StatsMgr := StatsMgrRef?):
            StatsMgr.RecordElimination(KillerAgent, VictimAgent)

        if (VictimFC := VictimAgent.GetFortCharacter[]):
            GetLobbyMenuManager().CustomizationManager.PlayKillEffectAt(KillerAgent, VictimFC)

        AwardPoint(KillerAgent)
        UpdateHUDScores()

    OnPlayerEliminated(Result : elimination_result) : void =
        if (RoundOver? or EliminationHandled?) then return

        Victim := Result.EliminatedCharacter
        var VictimIsP1 : logic = false

        if (P1 := Player1?, FC1 := P1.GetFortCharacter[], Victim = FC1):
            set VictimIsP1 = true
        else if (P1 := Player1?, VictimAgent := Victim.GetAgent[], VictimAgent = P1):
            set VictimIsP1 = true

        if (P1 := Player1?, P2 := Player2?):
            VictimAgent := if (VictimIsP1?) then P1 else P2
            OpponentAgent := if (VictimIsP1?) then P2 else P1
            HandleEliminationSafely(VictimAgent, OpponentAgent)

    HandleRoundTimeout()<suspends> : void =
        if (RoundOver? or EliminationHandled? or MatchOver? or MatchCancelled?) then return
        if (P1 := Player1?, P2 := Player2?):
            if (RoundOver? or MatchOver? or MatchCancelled?) then return
            if (FC1 := P1.GetFortCharacter[], FC2 := P2.GetFortCharacter[]):
                if (FC1.IsActive[], FC2.IsActive[]):
                    if (MatchSettings.OvertimeLength > 0.0):
                        MaxHealth := FC1.GetMaxHealth()
                        DamagePerSecond := MaxHealth / (MatchSettings.OvertimeLength - 1.0)
                        DamagePerTick := DamagePerSecond * 0.5
                        var OvertimeRemaining : float = MatchSettings.OvertimeLength

                        set OvertimeActive = true
                        UpdateHUDMatchState()

                        loop:
                            if (RoundOver? or MatchOver? or MatchCancelled?) then break
                            if (OvertimeRemaining <= 0.0) then break
                            UpdateHUDTimer(OvertimeRemaining)
                            Sleep(0.5)
                            if (RoundOver? or MatchOver? or MatchCancelled?) then break
                            set OvertimeRemaining -= 0.5
                            if (FC1.IsActive[], FC2.IsActive[]):
                                if (FC1.GetHealth() > 1.0):
                                    DamageDevice.SetMagnitude(DamagePerTick)
                                    DamageDevice.Pickup(P1)
                            if (FC2.IsActive[]):
                                if (FC2.GetHealth() > 1.0):
                                    DamageDevice.SetMagnitude(DamagePerTick)
                                    DamageDevice.Pickup(P2)
                            if (not FC1.IsActive[] or not FC2.IsActive[]):
                                set OvertimeActive = false
                                if (FC1.IsActive[] and not FC2.IsActive[]):
                                    AwardPoint(P1)
                                else if (FC2.IsActive[] and not FC1.IsActive[]):
                                    AwardPoint(P2)
                                else:
                                    HandleRoundDraw()
                                UpdateHUDMatchState()
                                break

                        if (OvertimeRemaining <= 0.0 and not RoundOver? and not MatchOver? and not MatchCancelled?):
                            UpdateHUDTimer(0.0)
                            set OvertimeActive = false
                            if (MatchSettings.UseTiebreaker?):
                                HP1 := FC1.GetHealth(), HP2 := FC2.GetHealth()
                                if (HP1 > HP2) then AwardPoint(P1)
                                else if (HP2 > HP1) then AwardPoint(P2)
                                else:
                                    HandleRoundDraw()
                            else:
                                HandleRoundDraw()
                            UpdateHUDMatchState()
                UpdateHUDMatchState()
            SetPlayersVulnerability(false)

    HandleRoundDraw() : void =
        set ConsecutiveDraws += 1
        set OvertimeActive = false
        set RoundResultVisible = true
        set RoundOver = true
        set Player1Won = false

        Print("[ArenaController] Round ended in a DRAW. Consecutive draws: {ConsecutiveDraws}/{MatchSettings.MaxDrawsBeforeCancel}.")

        UpdateHUDScores()
        UpdateHUDMatchState()

        if (HUD1 := Player1HUD?):
            set HUD1.RoundResultAnim = true
        if (HUD2 := Player2HUD?):
            set HUD2.RoundResultAnim = true

        if (ConsecutiveDraws >= MatchSettings.MaxDrawsBeforeCancel):
            Print("[ArenaController] Max consecutive draws reached ({ConsecutiveDraws}/{MatchSettings.MaxDrawsBeforeCancel}). Cancelling match.")
            set MatchCancelled = true
            set MatchOver = true

    UpdateHUDMatchState() : void =
        if (HUD1 := Player1HUD?):
            if (OvertimeActive?):
                set HUD1.ShowOvertime = true
            else:
                set HUD1.ShowOvertime = false

            if (RoundResultVisible?):
                if (ConsecutiveDraws > 0):
                    set HUD1.ShowVictory = false
                    set HUD1.ShowDefeat = false
                    set HUD1.ShowDraw = true
                else if (Player1Won?):
                    set HUD1.ShowVictory = true
                    set HUD1.ShowDefeat = false
                    set HUD1.ShowDraw = false
                else:
                    set HUD1.ShowVictory = false
                    set HUD1.ShowDefeat = true
                    set HUD1.ShowDraw = false
            else:
                set HUD1.ShowVictory = false
                set HUD1.ShowDefeat = false
                set HUD1.ShowDraw = false

        if (HUD2 := Player2HUD?):
            if (OvertimeActive?):
                set HUD2.ShowOvertime = true
            else:
                set HUD2.ShowOvertime = false

            if (RoundResultVisible?):
                if (ConsecutiveDraws > 0):
                    set HUD2.ShowVictory = false
                    set HUD2.ShowDefeat = false
                    set HUD2.ShowDraw = true
                else if (Player1Won?):
                    set HUD2.ShowVictory = false
                    set HUD2.ShowDefeat = true
                    set HUD2.ShowDraw = false
                else:
                    set HUD2.ShowVictory = true
                    set HUD2.ShowDefeat = false
                    set HUD2.ShowDraw = false
            else:
                set HUD2.ShowVictory = false
                set HUD2.ShowDefeat = false
                set HUD2.ShowDraw = false

    AwardPoint(ScoringAgent : agent) : void =
        if (P1 := Player1?, P2 := Player2?):
            if (ScoringAgent = P1):
                set Player1Score += 1
                set Player1Won = true
                if (HUD1 := Player1HUD?):
                    set HUD1.Player1ScoreAnim = true
                if (HUD2 := Player2HUD?):
                    set HUD2.Player1ScoreAnim = true
            else if (ScoringAgent = P2):
                set Player2Score += 1
                set Player1Won = false
                if (HUD1 := Player1HUD?):
                    set HUD1.Player2ScoreAnim = true
                if (HUD2 := Player2HUD?):
                    set HUD2.Player2ScoreAnim = true

        set ConsecutiveDraws = 0
        set OvertimeActive = false
        set RoundResultVisible = true
        set RoundOver = true

        UpdateHUDScores()
        UpdateHUDMatchState()

        if (HUD1 := Player1HUD?):
            set HUD1.RoundResultAnim = true
        if (HUD2 := Player2HUD?):
            set HUD2.RoundResultAnim = true

        WinningScoreTarget := GetWinningScoreTarget()
        if (Player1Score >= WinningScoreTarget or Player2Score >= WinningScoreTarget):
            set MatchOver = true

    GetWinningScoreTarget()<transacts> : int =
        SafeScore := if (MatchSettings.WinConditionScore > 0) then MatchSettings.WinConditionScore else 1
        if (MatchSettings.WinCondition = win_condition_type.FirstTo) then return SafeScore
        else:
            if (Half := Floor[(SafeScore * 1.0) / 2.0]) then return Half + 1
            return 1

    ResetArena(Map : arena_map) : void =
        # 1. Reset and Show the explosive device so it can explode repeatedly each round
        Map.LogicDevices.ResetExplosive.Reset()
        Map.LogicDevices.ResetExplosive.Show()

        # 2. Explode builds using whichever competitor agent is active
        var InstigatorFound : ?agent = false
        if (P1 := Player1?, P1Plr := player[P1], P1Plr.IsActive[]):
            set InstigatorFound = option { P1 }
        else if (P2 := Player2?, P2Plr := player[P2], P2Plr.IsActive[]):
            set InstigatorFound = option { P2 }

        if (Instigator := InstigatorFound?):
            Map.LogicDevices.ResetExplosive.Explode(Instigator)

        # 3. Refresh weapon spawners and arena powerups
        for (Spawner : Map.Gameplay.WeaponSpawners) do Spawner.Enable()
        for (P : Map.Gameplay.HealthPowerups) do P.Spawn()
        for (P : Map.Gameplay.DamagePowerups) do P.Spawn()
        for (P : Map.Gameplay.GrindPowerups) do P.Spawn()
        for (P : Map.Gameplay.StatPowerups) do P.Spawn()
        for (P : Map.Gameplay.VfxPowerups) do P.Spawn()

    PutPlayersInStasis() : void =
        if (P1 := Player1?, FC1 := P1.GetFortCharacter[], FC1.IsActive[], FC1.GetHealth() > 0.0):
            FC1.PutInStasis(stasis_args { AllowTurning := true, AllowFalling := false, AllowEmotes := false })
        if (P2 := Player2?, FC2 := P2.GetFortCharacter[], FC2.IsActive[], FC2.GetHealth() > 0.0):
            FC2.PutInStasis(stasis_args { AllowTurning := true, AllowFalling := false, AllowEmotes := false })

    RemovePlayersFromStasis() : void =
        if (P1 := Player1?, FC1 := P1.GetFortCharacter[]):
            FC1.ReleaseFromStasis()
        if (P2 := Player2?, FC2 := P2.GetFortCharacter[]):
            FC2.ReleaseFromStasis()

    HandlePlayerAbandonment(Gen : int) : void =
        if (Gen <> CurrentMatchGeneration or MatchOver? or MatchCancelled?) then return

        set EliminationHandled = true
        set RoundOver = true
        set OvertimeActive = false
        set MatchOver = true

        HideMatchHUD()

        P1Active := if (P1 := Player1?, P := player[P1], P.IsActive[]) then true else false
        P2Active := if (P2 := Player2?, P := player[P2], P.IsActive[]) then true else false

        if (StatsMgr := StatsMgrRef?):
            if (P1Active? and not P2Active?):
                if (Winner := Player1?, Loser := Player2?):
                    StatsMgr.Finalize1v1MatchStats(Winner, Loser)
            else if (P2Active? and not P1Active?):
                if (Winner := Player2?, Loser := Player1?):
                    StatsMgr.Finalize1v1MatchStats(Winner, Loser)
            else set MatchCancelled = true
        else set MatchCancelled = true

    EndMatch(Map : arena_map, Gen : int)<suspends> : void =
        if (Gen <> CurrentMatchGeneration) then return
        set CurrentMatchGeneration += 1

        ClearSubscriptions()
        PutPlayersInStasis()
        SetPlayersVulnerability(false)

        if (P1Val := Player1?, P2Val := Player2?, StatsMgr := StatsMgrRef?, MapMgr := MapMgrRef?, LoadoutMgr := LoadoutMgrRef?):
            Target := GetWinningScoreTarget()
            var MatchWinner : ?agent = false
            var MatchLoser : ?agent = false

            if (not MatchCancelled?):
                if (Player1Score >= Target):
                    set MatchWinner = option { P1Val }
                    set MatchLoser = option { P2Val }
                    StatsMgr.Finalize1v1MatchStats(P1Val, P2Val)
                    if (HUD1 := Player1HUD?):
                        set HUD1.ShowMatchWinner = true
                        set HUD1.ShowMatchLoser = false
                    if (HUD2 := Player2HUD?):
                        set HUD2.ShowMatchWinner = false
                        set HUD2.ShowMatchLoser = true
                else if (Player2Score >= Target):
                    set MatchWinner = option { P2Val }
                    set MatchLoser = option { P1Val }
                    StatsMgr.Finalize1v1MatchStats(P2Val, P1Val)
                    if (HUD1 := Player1HUD?):
                        set HUD1.ShowMatchWinner = false
                        set HUD1.ShowMatchLoser = true
                    if (HUD2 := Player2HUD?):
                        set HUD2.ShowMatchWinner = true
                        set HUD2.ShowMatchLoser = false
            else:
                if (HUD1 := Player1HUD?):
                    set HUD1.ShowMatchCancelled = true
                if (HUD2 := Player2HUD?):
                    set HUD2.ShowMatchCancelled = true

            HideMatchHUD()

            ActiveMenuMgr := GetLobbyMenuManager()

            # Compile Post-Match Contract Progress for both competitors
            ActiveMenuMgr.ContractManager.CompilePostMatchSummary(P1Val)
            ActiveMenuMgr.ContractManager.CompilePostMatchSummary(P2Val)

            # Remove weapons
            if (P1Plr := player[P1Val], P1Plr.IsActive[]):
                LoadoutMgr.ItemRemover.Remove(P1Val)
            if (P2Plr := player[P2Val], P2Plr.IsActive[]):
                LoadoutMgr.ItemRemover.Remove(P2Val)

            # Teleport to lobby safely
            if (Lobby := LobbyTP?):
                TeleportPlayerSafely(P1Val, Lobby)
                TeleportPlayerSafely(P2Val, Lobby)

            MapMgr.ReleaseMap(Map, MatchSettings.ArenaCooldown)
            RemovePlayersFromStasis()

            # Display After-Action Report (AAR) and Rematch interface
            ActiveMenuMgr.ShowPostMatchAAR(P1Val, P2Val, Player1Score, Player2Score, MatchWinner, MatchLoser)
        else:
            HideMatchHUD()
            RemovePlayersFromStasis()

        set Player1 = false
        set Player2 = false
        set Player1Score = 0
        set Player2Score = 0
        set CurrentRound = 0
        set BoundMap = false
        set LobbyTP = false
        set LoadoutMgrRef = false
        set StatsMgrRef = false
        set MapMgrRef = false
        set LobbyMenuManagerRef = false
        set MatchOver = false
        set MatchCancelled = false
        set RoundOver = false
        set EliminationHandled = false