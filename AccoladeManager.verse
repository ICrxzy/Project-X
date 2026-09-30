using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Verse }

# Tracks per-player elapsed session time for milestone accolades
player_playtime_tracker := class:
    var SecondsElapsed : float = 0.0
    var Last1MinAward : int = 0
    var Last5MinAward : int = 0
    var Last10MinAward : int = 0

accolade_manager := class(creative_device):
    # --- Service References ---
    @editable:
        ToolTip := StatsManagerInfo
    StatsManager : stats_manager = stats_manager{}

    @editable:
        ToolTip := MatchmakingManagerInfo
    MatchmakingManager : matchmaking_manager = matchmaking_manager{}

    @editable:
        ToolTip := ContractManagerInfo
    ContractManager : contract_manager = contract_manager{}

    # --- Accolade Devices ---
    @editable:
        ToolTip := FragAccoladeInfo
    FragAccolade : accolades_device = accolades_device{}

    @editable:
        ToolTip := DeathAccoladeInfo
    DeathAccolade : accolades_device = accolades_device{}

    @editable:
        ToolTip := MatchFoundAccoladeInfo
    MatchFoundAccolade : accolades_device = accolades_device{}

    @editable:
        ToolTip := WinAccoladeInfo
    WinAccolade : accolades_device = accolades_device{}

    @editable:
        ToolTip := LossAccoladeInfo
    LossAccolade : accolades_device = accolades_device{}

    @editable:
        ToolTip := DailyContractAccoladeInfo
    DailyContractAccolade : accolades_device = accolades_device{}

    @editable:
        ToolTip := WeeklyContractAccoladeInfo
    WeeklyContractAccolade : accolades_device = accolades_device{}

    @editable:
        ToolTip := MilestoneAccoladeInfo
    MilestoneAccolade : accolades_device = accolades_device{}

    @editable:
        ToolTip := Playtime1MinAccoladeInfo
    Playtime1MinAccolade : accolades_device = accolades_device{}

    @editable:
        ToolTip := Playtime5MinAccoladeInfo
    Playtime5MinAccolade : accolades_device = accolades_device{}

    @editable:
        ToolTip := Playtime10MinAccoladeInfo
    Playtime10MinAccolade : accolades_device = accolades_device{}

    @editable:
        ToolTip := IdleFarmAccoladeInfo
    IdleFarmAccolade : accolades_device = accolades_device{}

    @editable:
        ToolTip := IdleFarmButtonInfo
    IdleFarmButton : button_device = button_device{}

    var PlaytimeTrackers : [agent]player_playtime_tracker = map{}

    OnBegin<override>()<suspends> : void =
        GetPlayspace().PlayerAddedEvent().Subscribe(InitializePlayer)
        GetPlayspace().PlayerRemovedEvent().Subscribe(OnPlayerRemoved)

        for (P : GetPlayspace().GetPlayers()):
            InitializePlayer(P)

        StatsManager.KillfeedEvent.Subscribe(HandleKillfeedEvent)
        StatsManager.MatchFinalizedEvent.Subscribe(HandleMatchFinalized)
        MatchmakingManager.MatchFoundEvent.Subscribe(HandleMatchFound)
        ContractManager.ContractCompletedEvent.Subscribe(HandleContractCompleted)
        IdleFarmButton.InteractedWithEvent.Subscribe(HandleIdleFarmClick)

        spawn { PlaytimeLoop() }

    InitializePlayer(Agent : agent) : void =
        if (not PlaytimeTrackers[Agent]):
            if. set PlaytimeTrackers[Agent] = player_playtime_tracker{}

    OnPlayerRemoved(Player : player) : void =
        var NewTrackers : [agent]player_playtime_tracker = map{}
        for (Key -> Val : PlaytimeTrackers, Key <> Player):
            if. set NewTrackers[Key] = Val
        set PlaytimeTrackers = NewTrackers

    AwardFrag<public>(Agent : agent) : void = FragAccolade.Award(Agent)
    AwardDeath<public>(Agent : agent) : void = DeathAccolade.Award(Agent)
    AwardMatchFound<public>(Agent : agent) : void = MatchFoundAccolade.Award(Agent)
    AwardWin<public>(Agent : agent) : void = WinAccolade.Award(Agent)
    AwardLoss<public>(Agent : agent) : void = LossAccolade.Award(Agent)

    AwardContractCompleted<public>(Agent : agent, Category : contract_category) : void =
        case (Category):
            contract_category.Daily => DailyContractAccolade.Award(Agent)
            contract_category.Weekly => WeeklyContractAccolade.Award(Agent)
            contract_category.Milestone => MilestoneAccolade.Award(Agent)

    AwardIdleFarm<public>(Agent : agent) : void = IdleFarmAccolade.Award(Agent)

    HandleKillfeedEvent(Payload : tuple(?agent, agent, logic)) : void =
        KillerOpt := Payload(0), Victim := Payload(1)
        IsSuicide := Payload(2)

        if (Killer := KillerOpt?, Killer <> Victim, not IsSuicide?):
            AwardFrag(Killer), AwardDeath(Victim)
        else AwardDeath(Victim)

    HandleMatchFound(Payload : tuple(agent, agent, string, arena_map)) : void =
        P1 := Payload(0), P2 := Payload(1)
        AwardMatchFound(P1), AwardMatchFound(P2)

    HandleMatchFinalized(Payload : tuple(agent, agent)) : void =
        Winner := Payload(0), Loser := Payload(1)
        AwardWin(Winner), AwardLoss(Loser)

    HandleContractCompleted(Payload : tuple(agent, contract_category)) : void =
        Agent := Payload(0), Category := Payload(1)
        AwardContractCompleted(Agent, Category)

    HandleIdleFarmClick(Agent : agent) : void = AwardIdleFarm(Agent)

    PlaytimeLoop()<suspends> : void =
        loop:
            Sleep(1.0)
            for (P : GetPlayspace().GetPlayers(), P.IsActive[]):
                if (Tracker := PlaytimeTrackers[P]):
                    set Tracker.SecondsElapsed += 1.0
                    if (Minutes1 := Floor[Tracker.SecondsElapsed / 60.0]):
                        if (Minutes1 > Tracker.Last1MinAward):
                            set Tracker.Last1MinAward = Minutes1
                            Playtime1MinAccolade.Award(P)
                    if (Minutes5 := Floor[Tracker.SecondsElapsed / 300.0]):
                        if (Minutes5 > Tracker.Last5MinAward):
                            set Tracker.Last5MinAward = Minutes5
                            Playtime5MinAccolade.Award(P)
                    if (Minutes10 := Floor[Tracker.SecondsElapsed / 600.0]):
                        if (Minutes10 > Tracker.Last10MinAward):
                            set Tracker.Last10MinAward = Minutes10
                            Playtime10MinAccolade.Award(P)