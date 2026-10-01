using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Verse }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Random }

rematch_session := class<unique>:
    Player1 : agent
    Player2 : agent
    var P1WantsRematch : logic = false
    var P2WantsRematch : logic = false
    var P1InAAR : logic = true
    var P2InAAR : logic = true

player_menu_event_bridge := class:
    Manager : lobby_menu_manager
    Agent : agent

    # Core Navigation & Audio Callbacks
    OnPlayClicked() : void = Manager.HandlePlayButtonClicked(Agent)
    OnAutoQueueToggled() : void = Manager.HandleAutoQueueToggled(Agent)
    OnMusicToggled() : void = Manager.HandleMusicToggled(Agent)
    OnSoundFXToggled() : void = Manager.HandleSoundFXToggled(Agent)
    OnStatsButtonClicked() : void = Manager.HandleStatsButtonClicked(Agent)
    OnRematchClicked() : void = Manager.HandleRematchClicked(Agent)
    OnExitAARClicked() : void = Manager.HandleExitAARClicked(Agent)
    OnIdleFarmClicked() : void = Manager.HandleIdleFarmClicked(Agent)

    # Shop Buy Callbacks (8 Daily Slots + Featured Bundle)
    OnBuyDaily1Clicked() : void = Manager.HandleBuyDailyClicked(Agent, 0)
    OnBuyDaily2Clicked() : void = Manager.HandleBuyDailyClicked(Agent, 1)
    OnBuyDaily3Clicked() : void = Manager.HandleBuyDailyClicked(Agent, 2)
    OnBuyDaily4Clicked() : void = Manager.HandleBuyDailyClicked(Agent, 3)
    OnBuyDaily5Clicked() : void = Manager.HandleBuyDailyClicked(Agent, 4)
    OnBuyDaily6Clicked() : void = Manager.HandleBuyDailyClicked(Agent, 5)
    OnBuyDaily7Clicked() : void = Manager.HandleBuyDailyClicked(Agent, 6)
    OnBuyDaily8Clicked() : void = Manager.HandleBuyDailyClicked(Agent, 7)
    OnBuyFeaturedClicked() : void = Manager.HandleBuyFeaturedClicked(Agent)

    # Row 1: Backpack Navigation & Equip Callbacks
    OnBackpackPrevClicked() : void = Manager.HandleRowPrevClicked(Agent, customization_type.Backpack)
    OnBackpackNextClicked() : void = Manager.HandleRowNextClicked(Agent, customization_type.Backpack)
    OnBackpackSlot1EquipClicked() : void = Manager.HandleEquipRowSlotClicked(Agent, customization_type.Backpack, 0)
    OnBackpackSlot2EquipClicked() : void = Manager.HandleEquipRowSlotClicked(Agent, customization_type.Backpack, 1)
    OnBackpackSlot3EquipClicked() : void = Manager.HandleEquipRowSlotClicked(Agent, customization_type.Backpack, 2)

    # Row 2: Frag Effect Navigation & Equip Callbacks
    OnFragEffectPrevClicked() : void = Manager.HandleRowPrevClicked(Agent, customization_type.KillEffect)
    OnFragEffectNextClicked() : void = Manager.HandleRowNextClicked(Agent, customization_type.KillEffect)
    OnFragEffectSlot1EquipClicked() : void = Manager.HandleEquipRowSlotClicked(Agent, customization_type.KillEffect, 0)
    OnFragEffectSlot2EquipClicked() : void = Manager.HandleEquipRowSlotClicked(Agent, customization_type.KillEffect, 1)
    OnFragEffectSlot3EquipClicked() : void = Manager.HandleEquipRowSlotClicked(Agent, customization_type.KillEffect, 2)

    # Row 3: Emblem Navigation & Equip Callbacks
    OnEmblemPrevClicked() : void = Manager.HandleRowPrevClicked(Agent, customization_type.Emblem)
    OnEmblemNextClicked() : void = Manager.HandleRowNextClicked(Agent, customization_type.Emblem)
    OnEmblemSlot1EquipClicked() : void = Manager.HandleEquipRowSlotClicked(Agent, customization_type.Emblem, 0)
    OnEmblemSlot2EquipClicked() : void = Manager.HandleEquipRowSlotClicked(Agent, customization_type.Emblem, 1)
    OnEmblemSlot3EquipClicked() : void = Manager.HandleEquipRowSlotClicked(Agent, customization_type.Emblem, 2)

    # Row 4: Calling Card Navigation & Equip Callbacks
    OnCallingCardPrevClicked() : void = Manager.HandleRowPrevClicked(Agent, customization_type.Backplate)
    OnCallingCardNextClicked() : void = Manager.HandleRowNextClicked(Agent, customization_type.Backplate)
    OnCallingCardSlot1EquipClicked() : void = Manager.HandleEquipRowSlotClicked(Agent, customization_type.Backplate, 0)
    OnCallingCardSlot2EquipClicked() : void = Manager.HandleEquipRowSlotClicked(Agent, customization_type.Backplate, 1)
    OnCallingCardSlot3EquipClicked() : void = Manager.HandleEquipRowSlotClicked(Agent, customization_type.Backplate, 2)

    # Row 5: Title Navigation & Equip Callbacks
    OnTitlePrevClicked() : void = Manager.HandleRowPrevClicked(Agent, customization_type.Title)
    OnTitleNextClicked() : void = Manager.HandleRowNextClicked(Agent, customization_type.Title)
    OnTitleSlot1EquipClicked() : void = Manager.HandleEquipRowSlotClicked(Agent, customization_type.Title, 0)
    OnTitleSlot2EquipClicked() : void = Manager.HandleEquipRowSlotClicked(Agent, customization_type.Title, 1)
    OnTitleSlot3EquipClicked() : void = Manager.HandleEquipRowSlotClicked(Agent, customization_type.Title, 2)

    # Combat Card Settings Callbacks
    OnToggleRankClicked() : void = Manager.HandleToggleRankClicked(Agent)

lobby_menu_manager := class(creative_device):
    @editable:
        ToolTip := StatsManagerInfo
    StatsManager : stats_manager = stats_manager{}

    @editable:
        ToolTip := ContractManagerInfo
    ContractManager : contract_manager = contract_manager{}

    @editable:
        ToolTip := MatchmakingManagerInfo
    MatchmakingManager : matchmaking_manager = matchmaking_manager{}

    @editable:
        ToolTip := MapManagerInfo
    MapManager : map_manager = map_manager{}

    @editable:
        ToolTip := LobbyTPInfo
    LobbyTP : teleporter_device = teleporter_device{}

    @editable:
        ToolTip := AccoladeManagerInfo
    AccoladeManager : accolade_manager = accolade_manager{}

    @editable:
        ToolTip := LoadoutManagerInfo
    LoadoutManager : loadout_manager = loadout_manager{}

    @editable:
        ToolTip := EconomyManagerInfo
    EconomyManager : economy_manager = economy_manager{}

    @editable:
        ToolTip := ShopManagerInfo
    ShopManager : shop_manager = shop_manager{}

    @editable:
        ToolTip := CustomizationManagerInfo
    CustomizationManager : customization_manager = customization_manager{}

    @editable:
        ToolTip := EquipCosmeticSFXInfo
    EquipCosmeticSFX : audio_player_device = audio_player_device{}

    @editable MenuMusicPlayer : audio_player_device = audio_player_device{}
    @editable MatchFoundSFX : audio_player_device = audio_player_device{}
    @editable RankUpSFX : audio_player_device = audio_player_device{}
    @editable VictorySFX : audio_player_device = audio_player_device{}
    @editable DefeatSFX : audio_player_device = audio_player_device{}
    @editable UpdateInterval : float = 1.0

    var PlayerLobbyMenuMap : [agent]UI.LobbyMenuWidget = map{}
    var PlayerAARMap : [agent]UI.AARWidget = map{}
    var PlayerPreferencesMap : [agent]player_preferences = map{}
    var PlayerShowStatsMap : [agent]logic = map{}
    var ActiveRematchSessions : []rematch_session = array{}
    var PlayerLobbyMenuActiveMap : [agent]logic = map{}
    var PlayerAARActiveMap : [agent]logic = map{}

    OnBegin<override>()<suspends> : void =
        GetPlayspace().PlayerAddedEvent().Subscribe(InitializePlayerLobbyMenu)
        GetPlayspace().PlayerRemovedEvent().Subscribe(RemovePlayerLobbyMenu)

        # Pre-initialize dependencies before constructing the Lobby Menu UI
        for (P : GetPlayspace().GetPlayers()):
            EconomyManager.InitializePlayerEconomy(P)
            CustomizationManager.InitializePlayerCustomization(P)
            ContractManager.InitializePlayerContracts(P)
            InitializePlayerLobbyMenu(P)

        ContractManager.ContractsUpdatedEvent.Subscribe(HandleContractsUpdated)
        EconomyManager.CybercashUpdatedEvent.Subscribe(HandleCybercashUpdated)
        CustomizationManager.CustomizationUpdatedEvent.Subscribe(HandleCustomizationUpdated)
        StatsManager.PlayerStatsUpdatedEvent.Subscribe(HandlePlayerStatsUpdated)

        spawn { LobbyMenuUpdateLoop() }
        spawn { ShopCountdownLoop() }
        spawn { MatchFoundListener() }

    HandlePlayerStatsUpdated(Payload : tuple(agent, player_persistable_stats)) : void =
        Agent := Payload(0)
        if (MenuWidget := PlayerLobbyMenuMap[Agent]):
            UpdateStatsAndRankData(Agent, MenuWidget)
            UpdatePlayerCardPreview(Agent, MenuWidget)

    HandleExitAARClicked(Agent : agent) : void =
        MatchmakingManager.UnlockAgent(Agent)
        if. set PlayerAARActiveMap[Agent] = false
        if (PlayerObj := player[Agent], PUI := GetPlayerUI[PlayerObj], AAR := PlayerAARMap[Agent]):
            PUI.RemoveWidget(AAR)
            ShowLobbyMenuForPlayer(Agent)

        for (Session : ActiveRematchSessions):
            if (Session.Player1 = Agent):
                set Session.P1InAAR = false
                set Session.P1WantsRematch = false
                if (AAR2 := PlayerAARMap[Session.Player2]):
                    set AAR2.IsRematchAvailable = false
                    set AAR2.OpponentExitedAAR = true
            else if (Session.Player2 = Agent):
                set Session.P2InAAR = false
                set Session.P2WantsRematch = false
                if (AAR1 := PlayerAARMap[Session.Player1]):
                    set AAR1.IsRematchAvailable = false
                    set AAR1.OpponentExitedAAR = true

        if (Prefs := PlayerPreferencesMap[Agent], Prefs.AutoQueue?):
            MatchmakingManager.HandlePlayerReadyUp(Agent)

    HandleContractsUpdated(Agent : agent) : void =
        if (MenuWidget := PlayerLobbyMenuMap[Agent]):
            UpdateMenuData(Agent, MenuWidget)

    HandleCybercashUpdated(Payload : tuple(agent, int, int)) : void =
        Agent := Payload(0)
        if (MenuWidget := PlayerLobbyMenuMap[Agent]):
            UpdateEconomyData(Agent, MenuWidget)
            UpdateShopData(Agent, MenuWidget)

    HandleCustomizationUpdated(Agent : agent) : void =
        if (MenuWidget := PlayerLobbyMenuMap[Agent]):
            UpdateCustomizationData(Agent, MenuWidget)
            UpdateShopData(Agent, MenuWidget)
            UpdatePlayerCardPreview(Agent, MenuWidget)

    InitializePlayerLobbyMenu(Agent : agent) : void =
        if (Player := player[Agent], PlayerUI := GetPlayerUI[Player]):
            # Guarantee dependencies are initialized
            EconomyManager.InitializePlayerEconomy(Agent)
            CustomizationManager.InitializePlayerCustomization(Agent)

            MenuWidget := UI.LobbyMenuWidget{}
            set MenuWidget.ShowMatchFoundPopup = false
            set MenuWidget.ShowCombatCardStats = false
            PlayerUI.AddWidget(MenuWidget, player_ui_slot{ ZOrder := 0, InputMode := ui_input_mode.All })
            if. set PlayerLobbyMenuMap[Agent] = MenuWidget
            if. set PlayerLobbyMenuActiveMap[Agent] = true
            if (not PlayerPreferencesMap[Agent]):
                if. set PlayerPreferencesMap[Agent] = player_preferences{}
            if. set PlayerShowStatsMap[Agent] = false

            Bridge := player_menu_event_bridge{ Manager := Self, Agent := Agent }

            # Core Events
            MenuWidget.PlayClickedEvent.Subscribe(Bridge.OnPlayClicked)
            MenuWidget.AutoQueueToggledEvent.Subscribe(Bridge.OnAutoQueueToggled)
            MenuWidget.MusicToggledEvent.Subscribe(Bridge.OnMusicToggled)
            MenuWidget.SoundFXToggledEvent.Subscribe(Bridge.OnSoundFXToggled)
            MenuWidget.StatsButtonClickedEvent.Subscribe(Bridge.OnStatsButtonClicked)
            MenuWidget.IdleFarmClickedEvent.Subscribe(Bridge.OnIdleFarmClicked)

            # Shop Buy Events
            MenuWidget.ShopDaily1BuyClickedEvent.Subscribe(Bridge.OnBuyDaily1Clicked)
            MenuWidget.ShopDaily2BuyClickedEvent.Subscribe(Bridge.OnBuyDaily2Clicked)
            MenuWidget.ShopDaily3BuyClickedEvent.Subscribe(Bridge.OnBuyDaily3Clicked)
            MenuWidget.ShopDaily4BuyClickedEvent.Subscribe(Bridge.OnBuyDaily4Clicked)
            MenuWidget.ShopDaily5BuyClickedEvent.Subscribe(Bridge.OnBuyDaily5Clicked)
            MenuWidget.ShopDaily6BuyClickedEvent.Subscribe(Bridge.OnBuyDaily6Clicked)
            MenuWidget.ShopDaily7BuyClickedEvent.Subscribe(Bridge.OnBuyDaily7Clicked)
            MenuWidget.ShopDaily8BuyClickedEvent.Subscribe(Bridge.OnBuyDaily8Clicked)
            MenuWidget.ShopFeaturedBuyClickedEvent.Subscribe(Bridge.OnBuyFeaturedClicked)

            # Row 1: Backpack
            MenuWidget.BackpackPrevClickedEvent.Subscribe(Bridge.OnBackpackPrevClicked)
            MenuWidget.BackpackNextClickedEvent.Subscribe(Bridge.OnBackpackNextClicked)
            MenuWidget.BackpackSlot1EquipClickedEvent.Subscribe(Bridge.OnBackpackSlot1EquipClicked)
            MenuWidget.BackpackSlot2EquipClickedEvent.Subscribe(Bridge.OnBackpackSlot2EquipClicked)
            MenuWidget.BackpackSlot3EquipClickedEvent.Subscribe(Bridge.OnBackpackSlot3EquipClicked)

            # Row 2: Frag Effect
            MenuWidget.FragEffectPrevClickedEvent.Subscribe(Bridge.OnFragEffectPrevClicked)
            MenuWidget.FragEffectNextClickedEvent.Subscribe(Bridge.OnFragEffectNextClicked)
            MenuWidget.FragEffectSlot1EquipClickedEvent.Subscribe(Bridge.OnFragEffectSlot1EquipClicked)
            MenuWidget.FragEffectSlot2EquipClickedEvent.Subscribe(Bridge.OnFragEffectSlot2EquipClicked)
            MenuWidget.FragEffectSlot3EquipClickedEvent.Subscribe(Bridge.OnFragEffectSlot3EquipClicked)

            # Row 3: Emblem
            MenuWidget.EmblemPrevClickedEvent.Subscribe(Bridge.OnEmblemPrevClicked)
            MenuWidget.EmblemNextClickedEvent.Subscribe(Bridge.OnEmblemNextClicked)
            MenuWidget.EmblemSlot1EquipClickedEvent.Subscribe(Bridge.OnEmblemSlot1EquipClicked)
            MenuWidget.EmblemSlot2EquipClickedEvent.Subscribe(Bridge.OnEmblemSlot2EquipClicked)
            MenuWidget.EmblemSlot3EquipClickedEvent.Subscribe(Bridge.OnEmblemSlot3EquipClicked)

            # Row 4: Calling Card
            MenuWidget.CallingCardPrevClickedEvent.Subscribe(Bridge.OnCallingCardPrevClicked)
            MenuWidget.CallingCardNextClickedEvent.Subscribe(Bridge.OnCallingCardNextClicked)
            MenuWidget.CallingCardSlot1EquipClickedEvent.Subscribe(Bridge.OnCallingCardSlot1EquipClicked)
            MenuWidget.CallingCardSlot2EquipClickedEvent.Subscribe(Bridge.OnCallingCardSlot2EquipClicked)
            MenuWidget.CallingCardSlot3EquipClickedEvent.Subscribe(Bridge.OnCallingCardSlot3EquipClicked)

            # Row 5: Title
            MenuWidget.TitlePrevClickedEvent.Subscribe(Bridge.OnTitlePrevClicked)
            MenuWidget.TitleNextClickedEvent.Subscribe(Bridge.OnTitleNextClicked)
            MenuWidget.TitleSlot1EquipClickedEvent.Subscribe(Bridge.OnTitleSlot1EquipClicked)
            MenuWidget.TitleSlot2EquipClickedEvent.Subscribe(Bridge.OnTitleSlot2EquipClicked)
            MenuWidget.TitleSlot3EquipClickedEvent.Subscribe(Bridge.OnTitleSlot3EquipClicked)

            # Combat Card Settings
            MenuWidget.CustomToggleRankClickedEvent.Subscribe(Bridge.OnToggleRankClicked)

            UpdateMenuData(Agent, MenuWidget)
            PlayMusicForPlayer(Agent)
            CustomizationManager.ApplyEquippedBackpackVfx(Agent)

            spawn { RunTitleFlashLoop(Agent, MenuWidget) }
            spawn { RunHeadFlashLoop(Agent, MenuWidget) }
            spawn { RunCrossSpin1Loop(Agent, MenuWidget) }
            spawn { RunCrossSpin2Loop(Agent, MenuWidget) }
            spawn { RunTotalPlayerCountDisplay(Agent, MenuWidget) }

    HandleIdleFarmClicked(Agent : agent) : void = AccoladeManager.AwardIdleFarm(Agent)

    RemovePlayerLobbyMenu(Player : player) : void =
        StopMusicForPlayer(Player)
        HandlePlayerDisconnected(Player)
        if (MenuWidget := PlayerLobbyMenuMap[Player], PlayerUI := GetPlayerUI[Player]):
            PlayerUI.RemoveWidget(MenuWidget)
        if (AARWidget := PlayerAARMap[Player], PlayerUI := GetPlayerUI[Player]):
            PlayerUI.RemoveWidget(AARWidget)

        var NewMenuMap : [agent]UI.LobbyMenuWidget = map{}
        for (Key -> Val : PlayerLobbyMenuMap, Key <> Player):
            if. set NewMenuMap[Key] = Val
        set PlayerLobbyMenuMap = NewMenuMap

        var NewAARMap : [agent]UI.AARWidget = map{}
        for (Key -> Val : PlayerAARMap, Key <> Player):
            if. set NewAARMap[Key] = Val
        set PlayerAARMap = NewAARMap

    HideLobbyMenuForPlayer<public>(Agent : agent) : void =
        StopMusicForPlayer(Agent)
        if. set PlayerLobbyMenuActiveMap[Agent] = false
        if (Player := player[Agent], PlayerUI := GetPlayerUI[Player], MenuWidget := PlayerLobbyMenuMap[Agent]):
            PlayerUI.RemoveWidget(MenuWidget)

    ShowLobbyMenuForPlayer<public>(Agent : agent) : void =
        if (Player := player[Agent], PlayerUI := GetPlayerUI[Player]):
            MenuWidget := if (M := PlayerLobbyMenuMap[Agent]) then M else UI.LobbyMenuWidget{}
            set MenuWidget.ShowMatchFoundPopup = false
            PlayerUI.AddWidget(MenuWidget, player_ui_slot{ ZOrder := 0, InputMode := ui_input_mode.All })
            if. set PlayerLobbyMenuMap[Agent] = MenuWidget
            if. set PlayerLobbyMenuActiveMap[Agent] = true
            UpdateMenuData(Agent, MenuWidget)
            PlayMusicForPlayer(Agent)
            CustomizationManager.ApplyEquippedBackpackVfx(Agent)

            spawn { RunTitleFlashLoop(Agent, MenuWidget) }
            spawn { RunHeadFlashLoop(Agent, MenuWidget) }
            spawn { RunCrossSpin1Loop(Agent, MenuWidget) }
            spawn { RunCrossSpin2Loop(Agent, MenuWidget) }
            spawn { RunTotalPlayerCountDisplay(Agent, MenuWidget) }

    RunTotalPlayerCountDisplay(Agent : agent, MenuWidget : UI.LobbyMenuWidget)<suspends> : void =
        loop:
            if (PlayerLobbyMenuActiveMap[Agent] = false) then break
            Sleep(2.0)
            if (PlayerLobbyMenuActiveMap[Agent] = false) then break
            Players := GetPlayspace().GetPlayers()
            set MenuWidget.PlayerCountMessage = StringToMessage("{Players.Length}")

    PlayMusicForPlayer(Agent : agent) : void =
        if (Prefs := PlayerPreferencesMap[Agent], Prefs.MusicEnabled?):
            MenuMusicPlayer.Play(Agent)

    StopMusicForPlayer(Agent : agent) : void = MenuMusicPlayer.Stop(Agent)

    PlaySFXForPlayer(Agent : agent, SFX : audio_player_device) : void =
        if (Prefs := PlayerPreferencesMap[Agent], Prefs.SoundFXEnabled?):
            SFX.Play(Agent)

    RunTitleFlashLoop(Agent : agent, MenuWidget : UI.LobbyMenuWidget)<suspends> : void =
        loop:
            if (PlayerLobbyMenuActiveMap[Agent] = false) then break
            Cooldown := GetRandomFloat(4.0, 9.0)
            Sleep(Cooldown)
            if (PlayerLobbyMenuActiveMap[Agent] = false) then break

            BurstCount := GetRandomInt(1, 3)
            for (I := 1..BurstCount):
                set MenuWidget.AnimTitleFlash = true
                Sleep(0.13)
                set MenuWidget.AnimTitleFlash = false
                Sleep(0.13)

    RunHeadFlashLoop(Agent : agent, MenuWidget : UI.LobbyMenuWidget)<suspends> : void =
        loop:
            if (PlayerLobbyMenuActiveMap[Agent] = false) then break
            Cooldown := GetRandomFloat(4.0, 9.0)
            Sleep(Cooldown)
            if (PlayerLobbyMenuActiveMap[Agent] = false) then break

            BurstCount := GetRandomInt(1, 3)
            for (I := 1..BurstCount):
                set MenuWidget.AnimHeadFlash = true
                Sleep(0.30)
                set MenuWidget.AnimHeadFlash = false
                Sleep(0.13)

    RunCrossSpin1Loop(Agent : agent, MenuWidget : UI.LobbyMenuWidget)<suspends> : void =
        loop:
            if (PlayerLobbyMenuActiveMap[Agent] = false) then break
            Cooldown := GetRandomFloat(4.0, 9.0)
            Sleep(Cooldown)
            if (PlayerLobbyMenuActiveMap[Agent] = false) then break

            BurstCount := GetRandomInt(1, 3)
            for (I := 1..BurstCount):
                set MenuWidget.AnimCrossSpin1 = true
                Sleep(0.13)
                set MenuWidget.AnimCrossSpin1 = false
                Sleep(0.13)

    RunCrossSpin2Loop(Agent : agent, MenuWidget : UI.LobbyMenuWidget)<suspends> : void =
        loop:
            if (PlayerLobbyMenuActiveMap[Agent] = false) then break
            Cooldown := GetRandomFloat(4.0, 9.0)
            Sleep(Cooldown)
            if (PlayerLobbyMenuActiveMap[Agent] = false) then break

            BurstCount := GetRandomInt(1, 3)
            for (I := 1..BurstCount):
                set MenuWidget.AnimCrossSpin2 = true
                Sleep(0.13)
                set MenuWidget.AnimCrossSpin2 = false
                Sleep(0.13)

    RunAARCharacterGlitchLoop(Agent : agent, MenuWidget : UI.AARWidget)<suspends> : void =
        loop:
            if (PlayerAARActiveMap[Agent] = false) then break
            Cooldown := GetRandomFloat(4.0, 9.0)
            Sleep(Cooldown)
            if (PlayerAARActiveMap[Agent] = false) then break

            BurstCount := GetRandomInt(1, 3)
            for (I := 1..BurstCount):
                set MenuWidget.AnimCharacterGlitch = true
                Sleep(0.30)
                set MenuWidget.AnimCharacterGlitch = false
                Sleep(0.13)

    RunAARCrossSpin1Loop(Agent : agent, MenuWidget : UI.AARWidget)<suspends> : void =
        loop:
            if (PlayerAARActiveMap[Agent] = false) then break
            Cooldown := GetRandomFloat(4.0, 9.0)
            Sleep(Cooldown)
            if (PlayerAARActiveMap[Agent] = false) then break

            BurstCount := GetRandomInt(2, 4)
            for (I := 1..BurstCount):
                set MenuWidget.AnimCrossSpin1 = true
                Sleep(0.13)
                set MenuWidget.AnimCrossSpin1 = false
                Sleep(0.13)

    RunAARCrossSpin2Loop(Agent : agent, MenuWidget : UI.AARWidget)<suspends> : void =
        loop:
            if (PlayerAARActiveMap[Agent] = false) then break
            Cooldown := GetRandomFloat(4.0, 9.0)
            Sleep(Cooldown)
            if (PlayerAARActiveMap[Agent] = false) then break

            BurstCount := GetRandomInt(2, 4)
            for (I := 1..BurstCount):
                set MenuWidget.AnimCrossSpin2 = true
                Sleep(0.13)
                set MenuWidget.AnimCrossSpin2 = false
                Sleep(0.13)

    RunAARTitleFlashLoop(Agent : agent, MenuWidget : UI.AARWidget)<suspends> : void =
        loop:
            if (PlayerAARActiveMap[Agent] = false) then break
            Cooldown := GetRandomFloat(7.0, 15.0)
            Sleep(Cooldown)
            if (PlayerAARActiveMap[Agent] = false) then break

            BurstCount := GetRandomInt(2, 4)
            for (I := 1..BurstCount):
                set MenuWidget.AnimTitleFlash = true
                Sleep(0.13)
                set MenuWidget.AnimTitleFlash = false
                Sleep(0.13)

    RunAARScore1FlashLoop(Agent : agent, MenuWidget : UI.AARWidget)<suspends> : void =
        loop:
            if (PlayerAARActiveMap[Agent] = false) then break
            Cooldown := GetRandomFloat(7.0, 15.0)
            Sleep(Cooldown)
            if (PlayerAARActiveMap[Agent] = false) then break

            BurstCount := GetRandomInt(2, 4)
            for (I := 1..BurstCount):
                set MenuWidget.AnimScore1Flash = true
                Sleep(0.13)
                set MenuWidget.AnimScore1Flash = false
                Sleep(0.13)

    RunAARScore2FlashLoop(Agent : agent, MenuWidget : UI.AARWidget)<suspends> : void =
        loop:
            if (PlayerAARActiveMap[Agent] = false) then break
            Cooldown := GetRandomFloat(7.0, 15.0)
            Sleep(Cooldown)
            if (PlayerAARActiveMap[Agent] = false) then break

            BurstCount := GetRandomInt(2, 4)
            for (I := 1..BurstCount):
                set MenuWidget.AnimScore2Flash = true
                Sleep(0.13)
                set MenuWidget.AnimScore2Flash = false
                Sleep(0.13)

    RunAARRankIconGlitchLoop(Agent : agent, MenuWidget : UI.AARWidget)<suspends> : void =
        loop:
            if (PlayerAARActiveMap[Agent] = false) then break
            Cooldown := GetRandomFloat(7.0, 15.0)
            Sleep(Cooldown)
            if (PlayerAARActiveMap[Agent] = false) then break

            BurstCount := GetRandomInt(2, 4)
            for (I := 1..BurstCount):
                set MenuWidget.AnimRankIconGlitch = true
                Sleep(0.13)
                set MenuWidget.AnimRankIconGlitch = false
                Sleep(0.13)

    MatchFoundListener()<suspends> : void =
        loop:
            MatchData := MatchmakingManager.MatchFoundEvent.Await()
            P1 := MatchData(0)
            P2 := MatchData(1)
            MapName := MatchData(2)
            Arena := MatchData(3)
            spawn { RunMatchFoundSequence(P1, P2, MapName, Arena) }

    RunMatchFoundSequence(P1 : agent, P2 : agent, MapName : string, Arena : arena_map)<suspends> : void =
        MapMsg := StringToMessage(MapName)
        P1Name := AgentNameMessage(P1)
        P2Name := AgentNameMessage(P2)
        
        PlaySFXForPlayer(P1, MatchFoundSFX)
        PlaySFXForPlayer(P2, MatchFoundSFX)

        if (Menu1 := PlayerLobbyMenuMap[P1]):
            set Menu1.ShowMatchFoundPopup = true
            set Menu1.MatchFoundMapName = MapMsg
            set Menu1.MatchFoundMapThumbnail = Arena.General.SmallThumbnail
            set Menu1.MatchFoundOpponentName = P2Name
            set Menu1.MatchFoundCountdown = StringToMessage("3")
            set Menu1.MatchFoundAnim = true

        if (Menu2 := PlayerLobbyMenuMap[P2]):
            set Menu2.ShowMatchFoundPopup = true
            set Menu2.MatchFoundMapName = MapMsg
            set Menu2.MatchFoundMapThumbnail = Arena.General.SmallThumbnail
            set Menu2.MatchFoundOpponentName = P1Name
            set Menu2.MatchFoundCountdown = StringToMessage("3")
            set Menu2.MatchFoundAnim = true

        Sleep(1.0)  
        if (Menu1 := PlayerLobbyMenuMap[P1]):
            set Menu1.MatchFoundCountdown = StringToMessage("2")
        if (Menu2 := PlayerLobbyMenuMap[P2]):
            set Menu2.MatchFoundCountdown = StringToMessage("2")

        Sleep(1.0)
        if (Menu1 := PlayerLobbyMenuMap[P1]):
            set Menu1.MatchFoundCountdown = StringToMessage("1")
        if (Menu2 := PlayerLobbyMenuMap[P2]):
            set Menu2.MatchFoundCountdown = StringToMessage("1")

        Sleep(1.0)
        if (Menu1 := PlayerLobbyMenuMap[P1]):
            set Menu1.ShowMatchFoundPopup = false
        if (Menu2 := PlayerLobbyMenuMap[P2]):
            set Menu2.ShowMatchFoundPopup = false

        ActiveController := MapManager.ResolveControllerForMap(Arena)
        ActiveController.InitMatch(P1, P2, MatchmakingManager.MatchSettings, Arena, LobbyTP, LoadoutManager, StatsManager, MapManager, Self)

    ShowPostMatchAAR<public>(P1 : agent, P2 : agent, Score1 : int, Score2 : int, Winner : ?agent, Loser : ?agent) : void =
        MatchmakingManager.UnlockAgent(P1)
        MatchmakingManager.UnlockAgent(P2)

        NewSession := rematch_session{ Player1 := P1, Player2 := P2 }
        set ActiveRematchSessions += array{ NewSession }

        SetupAARForPlayer(P1, P2, Score1, Score2, if (W := Winner?, W = P1) then true else false)
        SetupAARForPlayer(P2, P1, Score2, Score1, if (W := Winner?, W = P2) then true else false)

    SetupAARForPlayer(Agent : agent, OpponentAgent : agent, SelfScore : int, OpponentScore : int, IsWinner : logic) : void =
        if (PlayerObj := player[Agent], PUI := GetPlayerUI[PlayerObj]):
            AARWidget := UI.AARWidget{}
            PUI.AddWidget(AARWidget, player_ui_slot{ ZOrder := 0, InputMode := ui_input_mode.All })
            if. set PlayerAARMap[Agent] = AARWidget
            if. set PlayerAARActiveMap[Agent] = true

            PlayMusicForPlayer(Agent)

            Bridge := player_menu_event_bridge{ Manager := Self, Agent := Agent }
            AARWidget.RematchClickedEvent.Subscribe(Bridge.OnRematchClicked)
            AARWidget.ExitAARClickedEvent.Subscribe(Bridge.OnExitAARClicked)

            set AARWidget.AARPlayerNameSelf = AgentNameMessage(Agent)
            set AARWidget.AARPlayerNameOpponent = AgentNameMessage(OpponentAgent)
            set AARWidget.AARScoreSelf = SelfScore
            set AARWidget.AARScoreOpponent = OpponentScore
            set AARWidget.AARIsWinner = IsWinner

            set AARWidget.AARMatchResultText = if (SelfScore = OpponentScore):
                StringToMessage("DRAW") 
            else if (SelfScore > OpponentScore):
                StringToMessage("VICTORY") 
            else StringToMessage("DEFEAT")

            set AARWidget.IsRematchAvailable = true
            set AARWidget.WaitingForOpponentRematch = false
            set AARWidget.OpponentWantsRematch = false
            set AARWidget.OpponentExitedAAR = false

            PopulateAARContracts(Agent, AARWidget)
            PlaySFXForPlayer(Agent, if (IsWinner?) then VictorySFX else DefeatSFX)

            if (Transition := StatsManager.GetLastMatchTransition(Agent)?):
                set AARWidget.AARRankName = StringToMessage(Transition.PreviousRank.RankName)
                set AARWidget.AARRankIcon = Transition.PreviousRank.RankIcon
                set AARWidget.AARRankProgressBar = Transition.PreviousProgressScalar
                set AARWidget.AARRankProgressPercent = StringToMessage(Transition.PreviousProgressPercent)

                set AARWidget.EloDeltaMessage = StringToMessage(Transition.EloDeltaText)
                set AARWidget.IsPositiveEloDelta = Transition.IsPositiveEloDelta
                set AARWidget.DidRankUp = false
                set AARWidget.DidRankDown = false

                spawn { AnimateProgressBar(Agent, AARWidget, Transition) }
                StatsManager.ClearLastMatchTransition(Agent)
            else if (StatsOpt := StatsManager.GetPlayerStats(Agent)?):
                CurrentRank := StatsManager.ResolveRankFromElo(StatsOpt.Elo)
                ProgressData := StatsManager.GetRankProgress(StatsOpt.Elo)

                set AARWidget.AARRankName = StringToMessage(CurrentRank.RankName)
                set AARWidget.AARRankIcon = CurrentRank.RankIcon
                set AARWidget.AARRankProgressBar = ProgressData(0)
                set AARWidget.AARRankProgressPercent = StringToMessage(ProgressData(1))

                set AARWidget.EloDeltaMessage = StringToMessage("+0%")
                set AARWidget.IsPositiveEloDelta = true
                set AARWidget.DidRankUp = false
                set AARWidget.DidRankDown = false

            spawn { RunAARCharacterGlitchLoop(Agent, AARWidget) }
            spawn { RunAARCrossSpin1Loop(Agent, AARWidget) }
            spawn { RunAARCrossSpin2Loop(Agent, AARWidget) }
            spawn { RunAARTitleFlashLoop(Agent, AARWidget) }
            spawn { RunAARScore1FlashLoop(Agent, AARWidget) }
            spawn { RunAARScore2FlashLoop(Agent, AARWidget) }
            spawn { RunAARRankIconGlitchLoop(Agent, AARWidget) }

    PopulateAARContracts(Agent : agent, AARWidget : UI.AARWidget) : void =
        Summaries := ContractManager.GetPostMatchSummary(Agent)
        set AARWidget.HasContractProgress = if (Summaries.Length > 0) then true else false

        if (Summaries.Length > 0, S1 := Summaries[0]):
            set AARWidget.Contract1Title = StringToMessage(S1.Title)
            set AARWidget.Contract1Progress = StringToMessage("{S1.NewProgress} / {S1.TargetProgress}")
            set AARWidget.Contract1Completed = S1.IsCompleted
        if (Summaries.Length > 1, S2 := Summaries[1]):
            set AARWidget.Contract2Title = StringToMessage(S2.Title)
            set AARWidget.Contract2Progress = StringToMessage("{S2.NewProgress} / {S2.TargetProgress}")
            set AARWidget.Contract2Completed = S2.IsCompleted
        if (Summaries.Length > 2, S3 := Summaries[2]):
            set AARWidget.Contract3Title = StringToMessage(S3.Title)
            set AARWidget.Contract3Progress = StringToMessage("{S3.NewProgress} / {S3.TargetProgress}")
            set AARWidget.Contract3Completed = S3.IsCompleted

        ContractManager.ClearMatchSummary(Agent)

    AnimateProgressBar(Agent : agent, MenuWidget : UI.AARWidget, Transition : match_rank_transition)<suspends> : void =
        StartPercent := if (SP := Round[Transition.PreviousProgressScalar * 100.0]) then SP else 0
        EndPercent := if (EP := Round[Transition.NewProgressScalar * 100.0]) then EP else 0

        if (Transition.DidRankUp?):
            PointsPhase1 := 100 - StartPercent
            DurationPhase1 := Clamp(0.4 + (PointsPhase1 * 0.015), 0.5, 1.2)
            Steps1 := if (S := Floor[DurationPhase1 / 0.025], S > 0) then S else 30
            for (I := 1..Steps1):
                T := (I * 1.0) / (Steps1 * 1.0)
                EasedT := 1.0 - ((1.0 - T) * (1.0 - T))
                CurrentScalar := Lerp(Transition.PreviousProgressScalar, 1.0, EasedT)
                if (PercentInt := Round[CurrentScalar * 100.0]):
                    set MenuWidget.AARRankProgressBar = CurrentScalar
                    set MenuWidget.AARRankProgressPercent = StringToMessage("{PercentInt}%")
                Sleep(0.025)

            set MenuWidget.AARRankName = StringToMessage(Transition.NewRank.RankName)
            set MenuWidget.AARRankIcon = Transition.NewRank.RankIcon
            set MenuWidget.DidRankUp = true
            PlaySFXForPlayer(Agent, RankUpSFX)
            set MenuWidget.AARRankProgressBar = 0.0
            set MenuWidget.AARRankProgressPercent = StringToMessage("0%")
            Sleep(0.25)

            DurationPhase2 := Clamp(0.4 + (EndPercent * 0.015), 0.5, 1.2)
            Steps2 := if (S := Floor[DurationPhase2 / 0.025], S > 0) then S else 30
            for (I := 1..Steps2):
                T := (I * 1.0) / (Steps2 * 1.0)
                EasedT := 1.0 - ((1.0 - T) * (1.0 - T))
                CurrentScalar := Lerp(0.0, Transition.NewProgressScalar, EasedT)
                if (PercentInt := Round[CurrentScalar * 100.0]):
                    set MenuWidget.AARRankProgressBar = CurrentScalar
                    set MenuWidget.AARRankProgressPercent = StringToMessage("{PercentInt}%")
                Sleep(0.025)
        else:
            PointsDelta := Abs(EndPercent - StartPercent)
            AnimDuration := Clamp(0.5 + (PointsDelta * 0.02), 0.6, 2.0)
            TotalSteps := if (S := Floor[AnimDuration / 0.025], S > 0) then S else 40
            for (I := 1..TotalSteps):
                T := (I * 1.0) / (TotalSteps * 1.0)
                EasedT := 1.0 - ((1.0 - T) * (1.0 - T))
                CurrentScalar := Lerp(Transition.PreviousProgressScalar, Transition.NewProgressScalar, EasedT)
                if (PercentInt := Round[CurrentScalar * 100.0]):
                    set MenuWidget.AARRankProgressBar = CurrentScalar
                    set MenuWidget.AARRankProgressPercent = StringToMessage("{PercentInt}%")
                Sleep(0.025)

            set MenuWidget.AARRankName = StringToMessage(Transition.NewRank.RankName)
            set MenuWidget.AARRankIcon = Transition.NewRank.RankIcon
            set MenuWidget.DidRankDown = Transition.DidRankDown

        set MenuWidget.AARRankProgressBar = Transition.NewProgressScalar
        set MenuWidget.AARRankProgressPercent = StringToMessage(Transition.NewProgressPercent)

    HandleRematchClicked(Agent : agent) : void =
        for (Session : ActiveRematchSessions):
            if (Session.Player1 = Agent and Session.P1InAAR?):
                set Session.P1WantsRematch = true
                if (AAR1 := PlayerAARMap[Agent]):
                    set AAR1.WaitingForOpponentRematch = true
                if (AAR2 := PlayerAARMap[Session.Player2]):
                    set AAR2.OpponentWantsRematch = true
                CheckAndTriggerRematch(Session)
                return
            else if (Session.Player2 = Agent and Session.P2InAAR?):
                set Session.P2WantsRematch = true
                if (AAR2 := PlayerAARMap[Agent]):
                    set AAR2.WaitingForOpponentRematch = true
                if (AAR1 := PlayerAARMap[Session.Player1]):
                    set AAR1.OpponentWantsRematch = true
                CheckAndTriggerRematch(Session)
                return

    CheckAndTriggerRematch(Session : rematch_session) : void =
        if (Session.P1WantsRematch?, Session.P2WantsRematch?, Session.P1InAAR?, Session.P2InAAR?):
            InactiveArenas := MapManager.GetInactiveMaps()
            if (InactiveArenas.Length > 0):
                ArenaIdx := GetRandomInt(0, InactiveArenas.Length - 1)
                if (SelectedArena := InactiveArenas[ArenaIdx]):
                    ActiveController := MapManager.ResolveControllerForMap(SelectedArena)

                    set ActiveRematchSessions = for (S : ActiveRematchSessions, S <> Session) do S
                    CloseAARForRematchPair(Session)

                    MapManager.ReserveMap(SelectedArena)
                    ActiveController.InitMatch(Session.Player1, Session.Player2, MatchmakingManager.MatchSettings, SelectedArena, LobbyTP, LoadoutManager, StatsManager, MapManager, Self)
    
    CloseAARForRematchPair(Session : rematch_session) : void =
        if. set PlayerAARActiveMap[Session.Player1] = false
        if. set PlayerAARActiveMap[Session.Player2] = false
        if (P1 := Session.Player1, P1Plr := player[P1], P1UI := GetPlayerUI[P1Plr], AAR1 := PlayerAARMap[P1]):
            P1UI.RemoveWidget(AAR1)
        if (P2 := Session.Player2, P2Plr := player[P2], P2UI := GetPlayerUI[P2Plr], AAR2 := PlayerAARMap[P2]):
            P2UI.RemoveWidget(AAR2)

    HandlePlayerDisconnected(LeavingAgent : agent) : void =
        for (Session : ActiveRematchSessions):
            if (Session.Player1 = LeavingAgent):
                set Session.P1InAAR = false
                if (AAR2 := PlayerAARMap[Session.Player2]):
                    set AAR2.IsRematchAvailable = false
                    set AAR2.OpponentExitedAAR = true
            else if (Session.Player2 = LeavingAgent):
                set Session.P2InAAR = false
                if (AAR1 := PlayerAARMap[Session.Player1]):
                    set AAR1.IsRematchAvailable = false
                    set AAR1.OpponentExitedAAR = true

    HandlePlayButtonClicked(Agent : agent) : void =
        if (MatchmakingManager.IsAgentLocked(Agent)?):
            MatchmakingManager.UnlockAgent(Agent)

        if (MatchmakingManager.IsPlayerQueued(Agent)?):
            MatchmakingManager.DequeuePlayer(Agent)
        else:
            MatchmakingManager.HandlePlayerReadyUp(Agent)

    HandleAutoQueueToggled(Agent : agent) : void =
        CurrentState := if (Prefs := PlayerPreferencesMap[Agent]) then Prefs.AutoQueue else false
        NewState := if (CurrentState?) then false else true
        if (Prefs := PlayerPreferencesMap[Agent]):
            NewPrefs := player_preferences{ AutoQueue := NewState, MusicEnabled := Prefs.MusicEnabled, SoundFXEnabled := Prefs.SoundFXEnabled }
            if. set PlayerPreferencesMap[Agent] = NewPrefs
        if (not NewState?):
            if (MatchmakingManager.IsPlayerQueued(Agent)?):
                MatchmakingManager.DequeuePlayer(Agent)
        if (MenuWidget := PlayerLobbyMenuMap[Agent]):
            set MenuWidget.AutoQueueEnabled = NewState

    HandleMusicToggled(Agent : agent) : void =
        CurrentState := if (Prefs := PlayerPreferencesMap[Agent]) then Prefs.MusicEnabled else true
        NewState := if (CurrentState?) then false else true
        if (Prefs := PlayerPreferencesMap[Agent]):
            NewPrefs := player_preferences{ AutoQueue := Prefs.AutoQueue, MusicEnabled := NewState, SoundFXEnabled := Prefs.SoundFXEnabled }
            if. set PlayerPreferencesMap[Agent] = NewPrefs
        if (NewState?):
            PlayMusicForPlayer(Agent)
        else:
            StopMusicForPlayer(Agent)
        if (MenuWidget := PlayerLobbyMenuMap[Agent]):
            set MenuWidget.MusicEnabled = NewState

    HandleSoundFXToggled(Agent : agent) : void =
        CurrentState := if (Prefs := PlayerPreferencesMap[Agent]) then Prefs.SoundFXEnabled else true
        NewState := if (CurrentState?) then false else true
        if (Prefs := PlayerPreferencesMap[Agent]):
            NewPrefs := player_preferences{ AutoQueue := Prefs.AutoQueue, MusicEnabled := Prefs.MusicEnabled, SoundFXEnabled := NewState }
            if. set PlayerPreferencesMap[Agent] = NewPrefs
        if (MenuWidget := PlayerLobbyMenuMap[Agent]):
            set MenuWidget.SoundFXEnabled = NewState

    HandleStatsButtonClicked(Agent : agent) : void =
        CurrentState := if (S := PlayerShowStatsMap[Agent]) then S else true
        NewState := if (CurrentState?) then false else true
        if. set PlayerShowStatsMap[Agent] = NewState
        if (MenuWidget := PlayerLobbyMenuMap[Agent]):
            set MenuWidget.ShowCombatCardStats = NewState

    # --- Shop Purchase Event Handlers ---
    HandleBuyDailyClicked(Agent : agent, SlotIndex : int) : void =
        DailyItems := ShopManager.GetDailyShopItems(Agent)
        if (Slot := DailyItems[SlotIndex]):
            Success := ShopManager.PurchaseShopItem(Agent, Slot.Def.Id)
            if (Success?):
                if (MenuWidget := PlayerLobbyMenuMap[Agent]):
                    UpdateEconomyData(Agent, MenuWidget)
                    UpdateShopData(Agent, MenuWidget)
                    UpdateCustomizationData(Agent, MenuWidget)
                    UpdatePlayerCardPreview(Agent, MenuWidget)

    HandleBuyFeaturedClicked(Agent : agent) : void =
        Success := ShopManager.PurchaseFeaturedBundle(Agent)
        if (Success?):
            if (MenuWidget := PlayerLobbyMenuMap[Agent]):
                UpdateEconomyData(Agent, MenuWidget)
                UpdateShopData(Agent, MenuWidget)
                UpdateCustomizationData(Agent, MenuWidget)
                UpdatePlayerCardPreview(Agent, MenuWidget)

    # --- 5-Row Customization Navigation & Equip Handlers ---
    HandleRowPrevClicked(Agent : agent, Category : customization_type) : void =
        CustomizationManager.CycleCarouselPrev(Agent, Category)
        if (MenuWidget := PlayerLobbyMenuMap[Agent]):
            UpdateCustomizationData(Agent, MenuWidget)

    HandleRowNextClicked(Agent : agent, Category : customization_type) : void =
        CustomizationManager.CycleCarouselNext(Agent, Category)
        if (MenuWidget := PlayerLobbyMenuMap[Agent]):
            UpdateCustomizationData(Agent, MenuWidget)

    HandleEquipRowSlotClicked(Agent : agent, Category : customization_type, SlotIndex : int) : void =
        PageData := CustomizationManager.GetCarouselPageData(Agent, Category)
        TargetSlot := case (SlotIndex):
            0 => PageData.Slot1
            1 => PageData.Slot2
            _ => PageData.Slot3

        if (not TargetSlot.IsLocked?, TargetSlot.ItemId <> ""):
            AttemptEquip := CustomizationManager.EquipItem(Agent, TargetSlot.ItemId)
            if (AttemptEquip?):
                EquipCosmeticSFX.Play(Agent)
                if (MenuWidget := PlayerLobbyMenuMap[Agent]):
                    UpdateCustomizationData(Agent, MenuWidget)
                    UpdatePlayerCardPreview(Agent, MenuWidget)

    HandleToggleRankClicked(Agent : agent) : void =
        CustomizationManager.ToggleRankVisibility(Agent)
        if (MenuWidget := PlayerLobbyMenuMap[Agent]):
            UpdateCustomizationData(Agent, MenuWidget)
            UpdatePlayerCardPreview(Agent, MenuWidget)

    # --- Real-Time Countdown Loop ---
    ShopCountdownLoop()<suspends> : void =
        loop:
            Sleep(1.0)
            DailyRem := ShopManager.GetDailySecondsRemaining()
            WeeklyRem := ShopManager.GetWeeklySecondsRemaining()
            DailyMsg := StringToMessage(FormatTime(DailyRem))
            WeeklyMsg := StringToMessage(FormatTime(WeeklyRem))

            for (Agent -> MenuWidget : PlayerLobbyMenuMap):
                if (PlayerLobbyMenuActiveMap[Agent] = true):
                    set MenuWidget.ShopDailyTimerMessage = DailyMsg
                    set MenuWidget.ShopWeeklyTimerMessage = WeeklyMsg

    LobbyMenuUpdateLoop()<suspends> : void =
        loop:
            Sleep(UpdateInterval)
            for (Agent -> MenuWidget : PlayerLobbyMenuMap):
                if (PlayerLobbyMenuActiveMap[Agent] = true):
                    # Only poll dynamic queue duration; catalog/shop/stats are updated via events
                    IsQueued := MatchmakingManager.IsPlayerQueued(Agent)
                    set MenuWidget.IsQueued = IsQueued
                    if (IsQueued?):
                        QDuration := MatchmakingManager.GetPlayerQueueDuration(Agent)
                        EstWait := MatchmakingManager.GetEstimatedWaitTime(Agent)
                        set MenuWidget.QueueTimeMessage = StringToMessage(FormatTime(QDuration))
                        set MenuWidget.EstWaitTimeMessage = StringToMessage("{FormatTime(EstWait)}s")

    UpdateMenuData(Agent : agent, MenuWidget : UI.LobbyMenuWidget) : void =
        UpdateStatsAndRankData(Agent, MenuWidget)
        UpdateContractsData(Agent, MenuWidget)
        UpdateEconomyData(Agent, MenuWidget)
        UpdateShopData(Agent, MenuWidget)
        UpdateCustomizationData(Agent, MenuWidget)
        UpdatePlayerCardPreview(Agent, MenuWidget)

        IsQueued := MatchmakingManager.IsPlayerQueued(Agent)
        set MenuWidget.IsQueued = IsQueued
        if (IsQueued?):
            QDuration := MatchmakingManager.GetPlayerQueueDuration(Agent)
            EstWait := MatchmakingManager.GetEstimatedWaitTime(Agent)
            set MenuWidget.QueueTimeMessage = StringToMessage(FormatTime(QDuration))
            set MenuWidget.EstWaitTimeMessage = StringToMessage("{FormatTime(EstWait)}s")

        if (ShowStats := PlayerShowStatsMap[Agent]):
            set MenuWidget.ShowCombatCardStats = ShowStats

        if (Prefs := PlayerPreferencesMap[Agent]):
            set MenuWidget.AutoQueueEnabled = Prefs.AutoQueue
            set MenuWidget.MusicEnabled = Prefs.MusicEnabled
            set MenuWidget.SoundFXEnabled = Prefs.SoundFXEnabled

    # --- Live Player Card Preview Update Routine ---
    UpdatePlayerCardPreview(Agent : agent, MenuWidget : UI.LobbyMenuWidget) : void =
        CardData := CustomizationManager.GetPlayerCardData(Agent)
        set MenuWidget.CardPlayerName = AgentNameMessage(Agent)
        set MenuWidget.CardEmblemThumbnail = CardData.EmblemThumbnail
        set MenuWidget.CardBackplateThumbnail = CardData.BackplateThumbnail
        set MenuWidget.CardTitleText = StringToMessage(CardData.TitleText)
        set MenuWidget.CardShowRank = CardData.ShowRank

    UpdateEconomyData(Agent : agent, MenuWidget : UI.LobbyMenuWidget) : void =
        Balance := EconomyManager.GetCybercashBalance(Agent)
        set MenuWidget.PlayerCybercash = Balance
        set MenuWidget.CybercashMessage = StringToMessage("${FormatNumber(Balance, false)}")

    UpdateShopData(Agent : agent, MenuWidget : UI.LobbyMenuWidget) : void =
        DailyItems := ShopManager.GetDailyShopItems(Agent)

        if (DailyItems.Length > 0, D1 := DailyItems[0]):
            set MenuWidget.ShopDaily1Name = StringToMessage(D1.Def.Name)
            set MenuWidget.ShopDaily1Thumbnail = D1.Def.Thumbnail
            set MenuWidget.ShopDaily1Price = StringToMessage("${FormatNumber(D1.FinalPrice, false)}")
            set MenuWidget.ShopDaily1Purchased = D1.IsPurchased
        if (DailyItems.Length > 1, D2 := DailyItems[1]):
            set MenuWidget.ShopDaily2Name = StringToMessage(D2.Def.Name)
            set MenuWidget.ShopDaily2Thumbnail = D2.Def.Thumbnail
            set MenuWidget.ShopDaily2Price = StringToMessage("${FormatNumber(D2.FinalPrice, false)}")
            set MenuWidget.ShopDaily2Purchased = D2.IsPurchased
        if (DailyItems.Length > 2, D3 := DailyItems[2]):
            set MenuWidget.ShopDaily3Name = StringToMessage(D3.Def.Name)
            set MenuWidget.ShopDaily3Thumbnail = D3.Def.Thumbnail
            set MenuWidget.ShopDaily3Price = StringToMessage("${FormatNumber(D3.FinalPrice, false)}")
            set MenuWidget.ShopDaily3Purchased = D3.IsPurchased
        if (DailyItems.Length > 3, D4 := DailyItems[3]):
            set MenuWidget.ShopDaily4Name = StringToMessage(D4.Def.Name)
            set MenuWidget.ShopDaily4Thumbnail = D4.Def.Thumbnail
            set MenuWidget.ShopDaily4Price = StringToMessage("${FormatNumber(D4.FinalPrice, false)}")
            set MenuWidget.ShopDaily4Purchased = D4.IsPurchased
        if (DailyItems.Length > 4, D5 := DailyItems[4]):
            set MenuWidget.ShopDaily5Name = StringToMessage(D5.Def.Name)
            set MenuWidget.ShopDaily5Thumbnail = D5.Def.Thumbnail
            set MenuWidget.ShopDaily5Price = StringToMessage("${FormatNumber(D5.FinalPrice, false)}")
            set MenuWidget.ShopDaily5Purchased = D5.IsPurchased
        if (DailyItems.Length > 5, D6 := DailyItems[5]):
            set MenuWidget.ShopDaily6Name = StringToMessage(D6.Def.Name)
            set MenuWidget.ShopDaily6Thumbnail = D6.Def.Thumbnail
            set MenuWidget.ShopDaily6Price = StringToMessage("${FormatNumber(D6.FinalPrice, false)}")
            set MenuWidget.ShopDaily6Purchased = D6.IsPurchased
        if (DailyItems.Length > 6, D7 := DailyItems[6]):
            set MenuWidget.ShopDaily7Name = StringToMessage(D7.Def.Name)
            set MenuWidget.ShopDaily7Thumbnail = D7.Def.Thumbnail
            set MenuWidget.ShopDaily7Price = StringToMessage("${FormatNumber(D7.FinalPrice, false)}")
            set MenuWidget.ShopDaily7Purchased = D7.IsPurchased
        if (DailyItems.Length > 7, D8 := DailyItems[7]):
            set MenuWidget.ShopDaily8Name = StringToMessage(D8.Def.Name)
            set MenuWidget.ShopDaily8Thumbnail = D8.Def.Thumbnail
            set MenuWidget.ShopDaily8Price = StringToMessage("${FormatNumber(D8.FinalPrice, false)}")
            set MenuWidget.ShopDaily8Purchased = D8.IsPurchased

        # Populate Prorated 5-Item Featured Bundle with Per-Slot Ownership Flags
        GetBundle := ShopManager.GetWeeklyFeaturedBundle(Agent)
        if (Bundle := GetBundle?):
            set MenuWidget.ShopFeaturedBundleName = StringToMessage(Bundle.BundleName)
            set MenuWidget.ShopFeaturedDiscount = StringToMessage("-{Bundle.DiscountPercent}% OFF!")
            set MenuWidget.ShopFeaturedPrice = StringToMessage("${FormatNumber(Bundle.FinalPrice, false)}")
            set MenuWidget.ShopFeaturedOriginalPrice = StringToMessage("${FormatNumber(Bundle.UnownedOriginalPrice, false)}")
            set MenuWidget.ShopFeaturedPurchased = Bundle.IsPurchased

            # Slot 1 - Backpack
            set MenuWidget.ShopFeaturedSlot1Name = StringToMessage(Bundle.BackpackItem.Name)
            set MenuWidget.ShopFeaturedSlot1Thumbnail = Bundle.BackpackItem.Thumbnail
            set MenuWidget.BundleSlot1IsOwned = Bundle.Slot1Owned

            # Slot 2 - Frag Effect (Kill Effect)
            set MenuWidget.ShopFeaturedSlot2Name = StringToMessage(Bundle.KillEffectItem.Name)
            set MenuWidget.ShopFeaturedSlot2Thumbnail = Bundle.KillEffectItem.Thumbnail
            set MenuWidget.BundleSlot2IsOwned = Bundle.Slot2Owned

            # Slot 3 - Emblem
            set MenuWidget.ShopFeaturedSlot3Name = StringToMessage(Bundle.EmblemItem.Name)
            set MenuWidget.ShopFeaturedSlot3Thumbnail = Bundle.EmblemItem.Thumbnail
            set MenuWidget.BundleSlot3IsOwned = Bundle.Slot3Owned

            # Slot 4 - Calling Card (Backplate)
            set MenuWidget.ShopFeaturedSlot4Name = StringToMessage(Bundle.BackplateItem.Name)
            set MenuWidget.ShopFeaturedSlot4Thumbnail = Bundle.BackplateItem.Thumbnail
            set MenuWidget.BundleSlot4IsOwned = Bundle.Slot4Owned

            # Slot 5 - Title
            set MenuWidget.ShopFeaturedSlot5Name = StringToMessage(Bundle.TitleItem.Name)
            set MenuWidget.ShopFeaturedSlot5Thumbnail = Bundle.TitleItem.Thumbnail
            set MenuWidget.BundleSlot5IsOwned = Bundle.Slot5Owned

    UpdateCustomizationData(Agent : agent, MenuWidget : UI.LobbyMenuWidget) : void =
        # 1. Backpack Row
        BPData := CustomizationManager.GetCarouselPageData(Agent, customization_type.Backpack)
        set MenuWidget.BackpackSlot1Name = StringToMessage(BPData.Slot1.Name)
        set MenuWidget.BackpackSlot1Thumbnail = BPData.Slot1.Thumbnail
        set MenuWidget.BackpackSlot1Equipped = BPData.Slot1.IsEquipped
        set MenuWidget.BackpackSlot1Locked = BPData.Slot1.IsLocked

        set MenuWidget.BackpackSlot2Name = StringToMessage(BPData.Slot2.Name)
        set MenuWidget.BackpackSlot2Thumbnail = BPData.Slot2.Thumbnail
        set MenuWidget.BackpackSlot2Equipped = BPData.Slot2.IsEquipped
        set MenuWidget.BackpackSlot2Locked = BPData.Slot2.IsLocked

        set MenuWidget.BackpackSlot3Name = StringToMessage(BPData.Slot3.Name)
        set MenuWidget.BackpackSlot3Thumbnail = BPData.Slot3.Thumbnail
        set MenuWidget.BackpackSlot3Equipped = BPData.Slot3.IsEquipped
        set MenuWidget.BackpackSlot3Locked = BPData.Slot3.IsLocked

        # 2. Frag Effect Row
        KEData := CustomizationManager.GetCarouselPageData(Agent, customization_type.KillEffect)
        set MenuWidget.FragEffectSlot1Name = StringToMessage(KEData.Slot1.Name)
        set MenuWidget.FragEffectSlot1Thumbnail = KEData.Slot1.Thumbnail
        set MenuWidget.FragEffectSlot1Equipped = KEData.Slot1.IsEquipped
        set MenuWidget.FragEffectSlot1Locked = KEData.Slot1.IsLocked

        set MenuWidget.FragEffectSlot2Name = StringToMessage(KEData.Slot2.Name)
        set MenuWidget.FragEffectSlot2Thumbnail = KEData.Slot2.Thumbnail
        set MenuWidget.FragEffectSlot2Equipped = KEData.Slot2.IsEquipped
        set MenuWidget.FragEffectSlot2Locked = KEData.Slot2.IsLocked

        set MenuWidget.FragEffectSlot3Name = StringToMessage(KEData.Slot3.Name)
        set MenuWidget.FragEffectSlot3Thumbnail = KEData.Slot3.Thumbnail
        set MenuWidget.FragEffectSlot3Equipped = KEData.Slot3.IsEquipped
        set MenuWidget.FragEffectSlot3Locked = KEData.Slot3.IsLocked

        # 3. Emblem Row
        EMData := CustomizationManager.GetCarouselPageData(Agent, customization_type.Emblem)
        set MenuWidget.EmblemSlot1Name = StringToMessage(EMData.Slot1.Name)
        set MenuWidget.EmblemSlot1Thumbnail = EMData.Slot1.Thumbnail
        set MenuWidget.EmblemSlot1Equipped = EMData.Slot1.IsEquipped
        set MenuWidget.EmblemSlot1Locked = EMData.Slot1.IsLocked

        set MenuWidget.EmblemSlot2Name = StringToMessage(EMData.Slot2.Name)
        set MenuWidget.EmblemSlot2Thumbnail = EMData.Slot2.Thumbnail
        set MenuWidget.EmblemSlot2Equipped = EMData.Slot2.IsEquipped
        set MenuWidget.EmblemSlot2Locked = EMData.Slot2.IsLocked

        set MenuWidget.EmblemSlot3Name = StringToMessage(EMData.Slot3.Name)
        set MenuWidget.EmblemSlot3Thumbnail = EMData.Slot3.Thumbnail
        set MenuWidget.EmblemSlot3Equipped = EMData.Slot3.IsEquipped
        set MenuWidget.EmblemSlot3Locked = EMData.Slot3.IsLocked

        # 4. Calling Card Row
        BKData := CustomizationManager.GetCarouselPageData(Agent, customization_type.Backplate)
        set MenuWidget.CallingCardSlot1Name = StringToMessage(BKData.Slot1.Name)
        set MenuWidget.CallingCardSlot1Thumbnail = BKData.Slot1.Thumbnail
        set MenuWidget.CallingCardSlot1Equipped = BKData.Slot1.IsEquipped
        set MenuWidget.CallingCardSlot1Locked = BKData.Slot1.IsLocked

        set MenuWidget.CallingCardSlot2Name = StringToMessage(BKData.Slot2.Name)
        set MenuWidget.CallingCardSlot2Thumbnail = BKData.Slot2.Thumbnail
        set MenuWidget.CallingCardSlot2Equipped = BKData.Slot2.IsEquipped
        set MenuWidget.CallingCardSlot2Locked = BKData.Slot2.IsLocked

        set MenuWidget.CallingCardSlot3Name = StringToMessage(BKData.Slot3.Name)
        set MenuWidget.CallingCardSlot3Thumbnail = BKData.Slot3.Thumbnail
        set MenuWidget.CallingCardSlot3Equipped = BKData.Slot3.IsEquipped
        set MenuWidget.CallingCardSlot3Locked = BKData.Slot3.IsLocked

        # 5. Title Row
        TIData := CustomizationManager.GetCarouselPageData(Agent, customization_type.Title)
        set MenuWidget.TitleSlot1Name = StringToMessage(TIData.Slot1.Name)
        set MenuWidget.TitleSlot1Thumbnail = TIData.Slot1.Thumbnail
        set MenuWidget.TitleSlot1Equipped = TIData.Slot1.IsEquipped
        set MenuWidget.TitleSlot1Locked = TIData.Slot1.IsLocked

        set MenuWidget.TitleSlot2Name = StringToMessage(TIData.Slot2.Name)
        set MenuWidget.TitleSlot2Thumbnail = TIData.Slot2.Thumbnail
        set MenuWidget.TitleSlot2Equipped = TIData.Slot2.IsEquipped
        set MenuWidget.TitleSlot2Locked = TIData.Slot2.IsLocked

        set MenuWidget.TitleSlot3Name = StringToMessage(TIData.Slot3.Name)
        set MenuWidget.TitleSlot3Thumbnail = TIData.Slot3.Thumbnail
        set MenuWidget.TitleSlot3Equipped = TIData.Slot3.IsEquipped
        set MenuWidget.TitleSlot3Locked = TIData.Slot3.IsLocked

        # Combat Card Rank Visibility Preference
        set MenuWidget.CustomShowRankOnCard = CustomizationManager.GetShowRankPreference(Agent)

    UpdateStatsAndRankData(Agent : agent, MenuWidget : UI.LobbyMenuWidget) : void =
        if (StatsOpt := StatsManager.GetPlayerStats(Agent)?):
            set MenuWidget.PlayerName = AgentNameMessage(Agent)
            set MenuWidget.PlayerKills = StatsOpt.Kills
            set MenuWidget.PlayerDeaths = StatsOpt.Deaths
            set MenuWidget.PlayerWins = StatsOpt.Wins
            set MenuWidget.PlayerLosses = StatsOpt.Losses
            set MenuWidget.PlayerHeadshots = StatsOpt.Headshots

            KD := if (StatsOpt.Deaths > 0) then (1.0 * StatsOpt.Kills) / (1.0 * StatsOpt.Deaths) else (1.0 * StatsOpt.Kills)
            set MenuWidget.PlayerKD = StringToMessage("{ToMultiplierString(KD, 2)}")

            WL := if (StatsOpt.Losses > 0) then (1.0 * StatsOpt.Wins) / (1.0 * StatsOpt.Losses) else (1.0 * StatsOpt.Wins)
            set MenuWidget.PlayerWinRate = StringToMessage("{ToMultiplierString(WL, 2)}")

            set MenuWidget.PlayerCurrentKillStreak = StatsOpt.CurrentKillStreak
            set MenuWidget.PlayerMaxKillStreak = StatsOpt.MaxKillStreak
            set MenuWidget.PlayerCurrentWinStreak = StatsOpt.CurrentWinStreak
            set MenuWidget.PlayerMaxWinStreak = StatsOpt.MaxWinStreak
            set MenuWidget.PlayerTotalMatches = StatsOpt.Wins + StatsOpt.Losses

            Rank := StatsManager.ResolveRankFromElo(StatsOpt.Elo)
            ProgressData := StatsManager.GetRankProgress(StatsOpt.Elo)
            set MenuWidget.PlayerRankTier = Rank.Tier
            set MenuWidget.CurrentRankName = StringToMessage(Rank.RankName)
            set MenuWidget.CurrentRankIcon = Rank.RankIcon
            set MenuWidget.CurrentRankProgressBar = ProgressData(0)
            set MenuWidget.CurrentRankProgressPercent = StringToMessage(ProgressData(1))

    UpdateContractsData(Agent : agent, MenuWidget : UI.LobbyMenuWidget) : void =
        DailyContracts := ContractManager.GetActiveDailyContracts(Agent)
        if (DailyContracts.Length > 0, D1 := DailyContracts[0]):
            set MenuWidget.Daily1Title = StringToMessage(D1.Title)
            set MenuWidget.Daily1Desc = StringToMessage(D1.Description)
            set MenuWidget.Daily1Progress = StringToMessage("{D1.CurrentProgress} / {D1.TargetProgress}")
            set MenuWidget.Daily1ProgressBar = D1.ProgressScalar
            set MenuWidget.Daily1Completed = D1.IsCompleted
        if (DailyContracts.Length > 1, D2 := DailyContracts[1]):
            set MenuWidget.Daily2Title = StringToMessage(D2.Title)
            set MenuWidget.Daily2Desc = StringToMessage(D2.Description)
            set MenuWidget.Daily2Progress = StringToMessage("{D2.CurrentProgress} / {D2.TargetProgress}")
            set MenuWidget.Daily2ProgressBar = D2.ProgressScalar
            set MenuWidget.Daily2Completed = D2.IsCompleted
        if (DailyContracts.Length > 2, D3 := DailyContracts[2]):
            set MenuWidget.Daily3Title = StringToMessage(D3.Title)
            set MenuWidget.Daily3Desc = StringToMessage(D3.Description)
            set MenuWidget.Daily3Progress = StringToMessage("{D3.CurrentProgress} / {D3.TargetProgress}")
            set MenuWidget.Daily3ProgressBar = D3.ProgressScalar
            set MenuWidget.Daily3Completed = D3.IsCompleted

        WeeklyContracts := ContractManager.GetActiveWeeklyContracts(Agent)
        if (WeeklyContracts.Length > 0, W1 := WeeklyContracts[0]):
            set MenuWidget.Weekly1Title = StringToMessage(W1.Title)
            set MenuWidget.Weekly1Desc = StringToMessage(W1.Description)
            set MenuWidget.Weekly1Progress = StringToMessage("{W1.CurrentProgress} / {W1.TargetProgress}")
            set MenuWidget.Weekly1ProgressBar = W1.ProgressScalar
            set MenuWidget.Weekly1Completed = W1.IsCompleted
        if (WeeklyContracts.Length > 1, W2 := WeeklyContracts[1]):
            set MenuWidget.Weekly2Title = StringToMessage(W2.Title)
            set MenuWidget.Weekly2Desc = StringToMessage(W2.Description)
            set MenuWidget.Weekly2Progress = StringToMessage("{W2.CurrentProgress} / {W2.TargetProgress}")
            set MenuWidget.Weekly2ProgressBar = W2.ProgressScalar
            set MenuWidget.Weekly2Completed = W2.IsCompleted
        if (WeeklyContracts.Length > 2, W3 := WeeklyContracts[2]):
            set MenuWidget.Weekly3Title = StringToMessage(W3.Title)
            set MenuWidget.Weekly3Desc = StringToMessage(W3.Description)
            set MenuWidget.Weekly3Progress = StringToMessage("{W3.CurrentProgress} / {W3.TargetProgress}")
            set MenuWidget.Weekly3ProgressBar = W3.ProgressScalar
            set MenuWidget.Weekly3Completed = W3.IsCompleted