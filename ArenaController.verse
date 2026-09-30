using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Verse }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Fortnite.com/FortPlayerUtilities }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }

# Single source of truth for match state
arena_state := enum { Idle, Loading, Stasis, Combat, RoundEnd, Overtime, Cleanup }

arena_controller := class(creative_device):
    @editable:
        ToolTip := LobbyMenuManagerInfo
    LobbyMenuManager : lobby_menu_manager = lobby_menu_manager{}

    @editable:
        ToolTip := InitialLoadingDurationInfo
    InitialLoadingDuration : float = 4.0
    
    @editable DamageDevice : health_powerup_device = health_powerup_device{}

    # --- Match State ---
    var CurrentState : arena_state = arena_state.Idle
    var CurrentMatchGeneration : int = 0
    var Player1 : ?agent = false
    var Player2 : ?agent = false
    var Player1Score : int = 0
    var Player2Score : int = 0
    var CurrentRound : int = 0
    var MatchSettings : match_settings = match_settings{}
    var BoundMap : ?arena_map = false
    var LobbyTP : ?teleporter_device = false
    
    # --- Dependencies ---
    var LoadoutMgrRef : ?loadout_manager = false
    var StatsMgrRef : ?stats_manager = false
    var MapMgrRef : ?map_manager = false

    # --- HUD Bindings ---
    var Player1HUD : ?UI.PlayerInfoWidget = false
    var Player2HUD : ?UI.PlayerInfoWidget = false

    var ConsecutiveDraws : int = 0
    var MatchSubscriptions : []cancelable = array{}
    var Player1Won : logic = false
    var RoundResultVisible : logic = false
    var OvertimeActive : logic = false

    # --- Initialization ---
    InitMatch<public>(Competitor1 : agent, Competitor2 : agent, Settings : match_settings, Map : arena_map, Lobby : teleporter_device, 
    LoadoutMgr : loadout_manager, StatsMgr : stats_manager, MapMgr : map_manager) : void =

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
        set ConsecutiveDraws = 0
        
        set CurrentState = arena_state.Loading

        LobbyMenuManager.HideLobbyMenuForPlayer(Competitor1)
        LobbyMenuManager.HideLobbyMenuForPlayer(Competitor2)
        
        MapMgr.ActivateMap(Map)
        ShowMatchHUD(Competitor1, Competitor2, Map)
        
        spawn { MatchLoop(Map, LocalGen) }

    OnBegin<override>()<suspends> : void = 
        GetPlayspace().PlayerRemovedEvent().Subscribe(HandlePlayerRemoved)

    MatchLoop(Map : arena_map, Gen : int)<suspends> : void =
        loop:
            if (Gen <> CurrentMatchGeneration or CurrentState = arena_state.Cleanup) then break
            Continue := RunRound(Map, Gen)
            if (not Continue?) then break
            if (Player1Score >= GetWinningScoreTarget() or Player2Score >= GetWinningScoreTarget()) then break
        CleanupMatch(Map, Gen)

    PlacePlayersInArena(Map : arena_map)<suspends> : logic =
        P1Trans := Map.Player1Spawn.GetTransform()
        P2Trans := Map.Player2Spawn.GetTransform()
        if (P1 := Player1?, P2 := Player2?):
            OptFC1 := AwaitActiveCharacter(P1, P1Trans.Translation, P1Trans.Rotation)
            OptFC2 := AwaitActiveCharacter(P2, P2Trans.Translation, P2Trans.Rotation)
            if (OptFC1?, OptFC2?):
                SetPlayersStasis(false)
                SetPlayersVulnerability(false)
                Map.Player1Spawn.Teleport(P1)
                Map.Player2Spawn.Teleport(P2)
                return true
        return false

    RunRound(Map : arena_map, Gen : int)<suspends> : logic =
        set CurrentRound += 1
        set RoundResultVisible = false
        ResetArena(Map)

        Placed := PlacePlayersInArena(Map)
        if (not Placed?) then return false
        if (CurrentRound = 1):
            UpdateHUDLoadingScreen(true)
            Sleep(InitialLoadingDuration)
        else Sleep(0.5)
        if (Gen <> CurrentMatchGeneration) then return false
        if (P1 := Player1?, P2 := Player2?, FC1 := P1.GetFortCharacter[], FC2 := P2.GetFortCharacter[]):
            Map.Player1Spawn.Teleport(P1)
            Map.Player2Spawn.Teleport(P2)
            Sleep(1.0)
            SetPlayersStasis(true)

            FC1.SetHealth(FC1.GetMaxHealth())
            FC1.SetShield(FC1.GetMaxShield())
            FC2.SetHealth(FC2.GetMaxHealth())
            FC2.SetShield(FC2.GetMaxShield())

            if (LoadoutMgr := LoadoutMgrRef?):
                LoadoutMgr.GrantMatchLoadout(P1, P2, Map.LoadoutIndex)
                LobbyMenuManager.CustomizationManager.ApplyEquippedBackpackVfx(P1)
                LobbyMenuManager.CustomizationManager.ApplyEquippedBackpackVfx(P2)

            if (CurrentRound = 1) then UpdateHUDLoadingScreen(false)
            set CurrentState = arena_state.Stasis
            UpdateUI()
            var StasisRemaining : float = MatchSettings.RoundStasisDuration
            UpdateHUDStasisCountdown(StasisRemaining, true)
            loop:
                if (StasisRemaining <= 0.0) then break
                Sleep(1.0)
                set StasisRemaining -= 1.0
                UpdateHUDStasisCountdown(StasisRemaining, true)
            UpdateHUDStasisCountdown(0.0, false)

            set CurrentState = arena_state.Combat
            SetPlayersStasis(false)
            Finished := RunCombatLoop(FC1, FC2, Map, Gen)

            SetPlayersStasis(true)
            SetPlayersVulnerability(false)
            if (not Finished?) then return false
            Sleep(MatchSettings.InterRoundDelay)
            return true
        return false

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

    UpdateHUDLoadingScreen(ShouldShow : logic) : void =
        if (HUD1 := Player1HUD?, HUD2 := Player2HUD?):
            set HUD1.ShowLoadingScreen = ShouldShow
            set HUD2.ShowLoadingScreen = ShouldShow

    RunCombatLoop(FC1 : fort_character, FC2 : fort_character, Map : arena_map, Gen : int)<suspends> : logic =
        var TimeRemaining : float = MatchSettings.RoundTimeLimit
        ClearSubscriptions()
        set MatchSubscriptions += array { FC1.EliminatedEvent().Subscribe(OnPlayerEliminated) }
        set MatchSubscriptions += array { FC2.EliminatedEvent().Subscribe(OnPlayerEliminated) }

        loop:
            if (Gen <> CurrentMatchGeneration or CurrentState = arena_state.Cleanup) then return false
            if (CurrentState = arena_state.RoundEnd) then return true
            if (TimeRemaining <= 0.0):
                UpdateHUDTimer(0.0)
                HandleRoundTimeout(FC1, FC2)
                return true
            
            UpdateHUDTimer(TimeRemaining)
            Sleep(1.0)
            set TimeRemaining -= 1.0

    CleanupMatch(Map : arena_map, Gen : int) : void =
        if (Gen <> CurrentMatchGeneration) then return
        
        set CurrentState = arena_state.Cleanup
        ClearSubscriptions()
        SetPlayersStasis(false)
        SetPlayersVulnerability(false)
        HideMatchHUD()
        
        if (P1 := Player1?, P2 := Player2?, Stats := StatsMgrRef?, MapMgr := MapMgrRef?):
            if (Player1Score >= GetWinningScoreTarget() or Player2Score >= GetWinningScoreTarget()):
                Stats.Finalize1v1MatchStats(P1, P2)
            if (Lobby := LobbyTP?):
                Lobby.Teleport(P1)
                Lobby.Teleport(P2)
            MapMgr.ReleaseMap(Map, MatchSettings.ArenaCooldown)
        set CurrentState = arena_state.Idle

    # --- Gameplay Logic ---
    OnPlayerEliminated(Result : elimination_result) : void =
        if (CurrentState <> arena_state.Combat and CurrentState <> arena_state.Overtime) then return
        Victim := Result.EliminatedCharacter
        if (VictimAgent := Victim.GetAgent[], P1 := Player1?, P2 := Player2?, Stats := StatsMgrRef?):
            SetPlayersVulnerability(false)
            SetPlayersStasis(true)
            
            Opponent := if (VictimAgent = P1) then P2 else P1
            
            var IsSuicide : logic = false
            if (KillerChar := Result.EliminatingCharacter?):
                if (KillerChar = Victim): 
                    set IsSuicide = true
                else if (KillerAgent := KillerChar.GetAgent[]):
                    if (KillerAgent = VictimAgent): 
                        set IsSuicide = true
                    else if (KillerAgent <> Opponent): 
                        set IsSuicide = true
                else set IsSuicide = true
            else set IsSuicide = true

            if (IsSuicide?):
                Stats.RecordSuicide(VictimAgent)
                if (MatchSettings.SubtractScoreOnSuicide?):
                    if (VictimAgent = P1): 
                        set Player1Score = Max(Player1Score - 1, 0)
                    else set Player2Score = Max(Player2Score - 1, 0)
                else AwardPoint(Opponent)
            else:
                Stats.RecordElimination(Opponent, VictimAgent)
                LobbyMenuManager.CustomizationManager.PlayKillEffectAt(Opponent, Victim)
                AwardPoint(Opponent)

            UpdateHUDScores()
            set CurrentState = arena_state.RoundEnd
            set RoundResultVisible = true

    HandleRoundTimeout(FC1 : fort_character, FC2 : fort_character)<suspends> : void =
        if (MatchSettings.OvertimeLength > 0.0):
            set CurrentState = arena_state.Overtime
            set OvertimeActive = true
            
            MaxHealth := FC1.GetMaxHealth()
            DamagePerSecond := MaxHealth / (MatchSettings.OvertimeLength - 1.0)
            DamagePerTick := DamagePerSecond * 0.5
            var OvertimeRemaining : float = MatchSettings.OvertimeLength

            loop:
                if (CurrentState <> arena_state.Overtime) then break
                if (OvertimeRemaining <= 0.0) then break
                if(P1 := Player1?, P2 := Player2?):
                    UpdateHUDTimer(OvertimeRemaining)
                    Sleep(0.5)
                    set OvertimeRemaining -= 0.5
                    if (CurrentState <> arena_state.Overtime) then break
                    if (FC1.IsActive[], FC1.GetHealth() > 1.0):
                        DamageDevice.SetMagnitude(DamagePerTick)
                        DamageDevice.Pickup(P1)
                    if (FC2.IsActive[], FC2.GetHealth() > 1.0):
                        DamageDevice.SetMagnitude(DamagePerTick)
                        DamageDevice.Pickup(P2)
                    if (not FC1.IsActive[] or not FC2.IsActive[]):
                        set OvertimeActive = false
                        if (FC1.IsActive[], not FC2.IsActive[]) { AwardPoint(P1) }
                        else if (FC2.IsActive[], not FC1.IsActive[]) { AwardPoint(P2) }
                        else HandleRoundDraw()
                        break

            if (CurrentState = arena_state.Overtime, OvertimeRemaining <= 0.0):
                UpdateHUDTimer(0.0)
                set OvertimeActive = false
                if (MatchSettings.UseTiebreaker?):
                    if(P1 := Player1?, P2 := Player2?):
                        if (FC1.GetHealth() > FC2.GetHealth()) { AwardPoint(P1) }
                        else if (FC2.GetHealth() > FC1.GetHealth()) { AwardPoint(P2) }
                        else HandleRoundDraw()
                else HandleRoundDraw()
        else HandleRoundDraw()

    HandleRoundDraw() : void =
        set ConsecutiveDraws += 1
        set OvertimeActive = false
        set RoundResultVisible = true
        UpdateHUDScores()
        UpdateUI()

    AwardPoint(ScoringAgent : agent) : void =
        if (P1 := Player1?, P2 := Player2?):
            if (ScoringAgent = P1):
                set Player1Score += 1
                set Player1Won = true
            else if (ScoringAgent = P2):
                set Player2Score += 1
                set Player1Won = false

        set ConsecutiveDraws = 0
        set OvertimeActive = false
        set RoundResultVisible = true
        UpdateHUDScores()
        UpdateUI()

    # --- UI & Utilities ---
    UpdateUI() : void =
        if (HUD1 := Player1HUD?, HUD2 := Player2HUD?):
            RoundStartPlaying := if (CurrentState = arena_state.Stasis, CurrentRound = 1) then true else false
            set HUD1.RoundStartAnim = RoundStartPlaying
            set HUD1.ShowLoadingScreen = RoundStartPlaying
            set HUD2.ShowLoadingScreen = if (CurrentState = arena_state.Loading) then true else false
            set HUD1.ShowOvertime = if (CurrentState = arena_state.Overtime) then true else false
            set HUD2.ShowOvertime = if (CurrentState = arena_state.Overtime) then true else false
            set HUD1.RoundResultAnim = RoundResultVisible
            set HUD2.RoundResultAnim = RoundResultVisible

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
            P2UI.AddWidget(HUD2, player_ui_slot{ ZOrder := 10, InputMode := ui_input_mode.None })
            set Player2HUD = option { HUD2 }

    HideMatchHUD() : void =
        if (P1 := Player1?, P1Plr := player[P1], P1UI := GetPlayerUI[P1Plr], HUD1 := Player1HUD?):
            P1UI.RemoveWidget(HUD1)
        if (P2 := Player2?, P2Plr := player[P2], P2UI := GetPlayerUI[P2Plr], HUD2 := Player2HUD?):
            P2UI.RemoveWidget(HUD2)
        set Player1HUD = false
        set Player2HUD = false

    UpdateHUDTimer(TimeRemaining : float) : void =
        TimerMsg := StringToMessage(FormatTime(TimeRemaining))
        if (HUD1 := Player1HUD?, HUD2 := Player2HUD?):
            set HUD1.RoundTimer = TimerMsg
            set HUD2.RoundTimer = TimerMsg

    UpdateHUDScores() : void =
        if (HUD1 := Player1HUD?, HUD2 := Player2HUD?):
            set HUD1.Player1Score = Player1Score
            set HUD1.Player2Score = Player2Score
            set HUD2.Player1Score = Player1Score
            set HUD2.Player2Score = Player2Score

    GetWinningScoreTarget()<transacts> : int =
        SafeScore := if (MatchSettings.WinConditionScore > 0) then MatchSettings.WinConditionScore else 1
        if (MatchSettings.WinCondition = win_condition_type.FirstTo) then return SafeScore
        else:
            if (Half := Floor[(SafeScore * 1.0) / 2.0]) then return Half + 1
            return 1

    ResetArena(Map : arena_map) : void =
        if (Instigator := Player1?) { Map.LogicDevices.ResetExplosive.Explode(Instigator) }
        for (Spawner : Map.Gameplay.WeaponSpawners) do Spawner.Enable()
        for (P : Map.Gameplay.HealthPowerups) do P.Spawn()
        for (P : Map.Gameplay.DamagePowerups) do P.Spawn()
        for (P : Map.Gameplay.GrindPowerups) do P.Spawn()
        for (P : Map.Gameplay.StatPowerups) do P.Spawn()
        for (P : Map.Gameplay.VfxPowerups) do P.Spawn()

    SetPlayersStasis(InStasis : logic) : void =
        Args := stasis_args { AllowTurning := false, AllowFalling := true, AllowEmotes := false }
        if (P1 := Player1?, FC1 := P1.GetFortCharacter[]):
            if (InStasis?) then FC1.PutInStasis(Args) else FC1.ReleaseFromStasis()
        if (P2 := Player2?, FC2 := P2.GetFortCharacter[]):
            if (InStasis?) then FC2.PutInStasis(Args) else FC2.ReleaseFromStasis()

    SetPlayersVulnerability(Vulnerable : logic) : void =
        if (P1 := Player1?, FC1 := P1.GetFortCharacter[]):
            FC1.SetVulnerability(Vulnerable)
        if (P2 := Player2?, FC2 := P2.GetFortCharacter[]):
            FC2.SetVulnerability(Vulnerable)

    AwaitActiveCharacter(Agent : agent, Pos : vector3, Rot : rotation)<suspends> : ?fort_character =
        if (FC := Agent.GetFortCharacter[], FC.IsActive[]) then return option { FC }
        Agent.Respawn(Pos, Rot)
        for (I := 0..200):
            Sleep(0.05)
            if (FC := Agent.GetFortCharacter[], FC.IsActive[]):
                return option { FC }
        return false

    ClearSubscriptions() : void =
        for (Sub : MatchSubscriptions) do Sub.Cancel()
        set MatchSubscriptions = array{}

    HandlePlayerRemoved(Player : player) : void =
        if (CurrentState = arena_state.Idle or CurrentState = arena_state.Cleanup) then return
        if (P1 := Player1?, P1Player := player[P1], P1Player = Player):
            set CurrentState = arena_state.Cleanup
        else if (P2 := Player2?, P2Player := player[P2], P2Player = Player):
            set CurrentState = arena_state.Cleanup