using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Verse }
using { /Verse.org/Random }

contract_manager := class(creative_device):
    @editable:
        ToolTip := StatsManagerInfo
    StatsManager : stats_manager = stats_manager{}

    @editable:
        ToolTip := EconomyManagerInfo
    EconomyManager : economy_manager = economy_manager{}

    @editable:
        ToolTip := CustomizationManagerInfo
    CustomizationManager : customization_manager = customization_manager{}

    # Active runtime cache per agent
    var ActiveContractsMap : [agent]player_persistable_contracts = map{}
    var MatchPreStateMap : [agent]player_persistable_contracts = map{}
    var MatchSummaryMap : [agent][]contract_match_summary = map{}
    var LastPlaytimeCheckTime : float = 0.0

    # Contract change notification event
    ContractsUpdatedEvent<public> : event(agent) = event(agent){}
    ContractCompletedEvent<public> : event(tuple(agent, contract_category)) = event(tuple(agent, contract_category)){}

    OnBegin<override>()<suspends> : void =
        set LastPlaytimeCheckTime = GetSimulationElapsedTime()
        GetPlayspace().PlayerAddedEvent().Subscribe(InitializePlayerContracts)
        GetPlayspace().PlayerRemovedEvent().Subscribe(OnPlayerRemoved)

        for (P : GetPlayspace().GetPlayers()):
            InitializePlayerContracts(P)

        StatsManager.KillfeedEvent.Subscribe(HandleKillfeedEvent)
        StatsManager.PlayerStatsUpdatedEvent.Subscribe(HandlePlayerStatsUpdated)

        spawn { PlaytimeTrackingLoop() }

    OnPlayerRemoved(P : player) : void =
        SavePlayerContracts(P)
        var NewActiveMap : [agent]player_persistable_contracts = map{}
        for (Key -> Val : ActiveContractsMap, Key <> P):
            if. set NewActiveMap[Key] = Val
        set ActiveContractsMap = NewActiveMap

        var NewPreMap : [agent]player_persistable_contracts = map{}
        for (Key -> Val : MatchPreStateMap, Key <> P):
            if. set NewPreMap[Key] = Val
        set MatchPreStateMap = NewPreMap

        var NewSummaryMap : [agent][]contract_match_summary = map{}
        for (Key -> Val : MatchSummaryMap, Key <> P):
            if. set NewSummaryMap[Key] = Val
        set MatchSummaryMap = NewSummaryMap

    # --- Contract Pool Catalog (With Mastery Milestone Cosmetic Rewards) ---
    GetContractDefinitions<public>()<transacts> : []contract_definition =
        array:
            # 8.1 Daily Pool
            contract_definition{ Id := "DAILY_FRAG_03", Category := contract_category.Daily, Title := "Frag 3 Players", Description := "Frag 3 opponent players in 1v1 arena matches.", RequirementType := contract_requirement_type.Frags, TargetValue := 3 },
            contract_definition{ Id := "DAILY_FRAG_05", Category := contract_category.Daily, Title := "Frag 5 Players", Description := "Frag 5 opponent players in 1v1 arena matches.", RequirementType := contract_requirement_type.Frags, TargetValue := 5 },
            contract_definition{ Id := "DAILY_FRAG_10", Category := contract_category.Daily, Title := "Frag 10 Players", Description := "Frag 10 opponent players in 1v1 arena matches.", RequirementType := contract_requirement_type.Frags, TargetValue := 10 },
            contract_definition{ Id := "DAILY_DEATH_03", Category := contract_category.Daily, Title := "Get Fragged 3 Times", Description := "Get Fragged 3 times during arena combat.", RequirementType := contract_requirement_type.Deaths, TargetValue := 3 },
            contract_definition{ Id := "DAILY_DEATH_06", Category := contract_category.Daily, Title := "Get Fragged 6 Times", Description := "Get Fragged 6 times during arena combat.", RequirementType := contract_requirement_type.Deaths, TargetValue := 6 },
            contract_definition{ Id := "DAILY_DEATH_10", Category := contract_category.Daily, Title := "Get Fragged 10 Times", Description := "Get Fragged 10 times during arena combat.", RequirementType := contract_requirement_type.Deaths, TargetValue := 10 },
            contract_definition{ Id := "DAILY_WINS_02", Category := contract_category.Daily, Title := "Win 2 Matches", Description := "Win 2 completed 1v1 arena matches.", RequirementType := contract_requirement_type.Wins, TargetValue := 2 },
            contract_definition{ Id := "DAILY_WINS_03", Category := contract_category.Daily, Title := "Win 3 Matches", Description := "Win 3 completed 1v1 arena matches.", RequirementType := contract_requirement_type.Wins, TargetValue := 3 },
            contract_definition{ Id := "DAILY_MATCHES_03", Category := contract_category.Daily, Title := "Play 3 Matches", Description := "Complete 3 full 1v1 arena matches.", RequirementType := contract_requirement_type.MatchesPlayed, TargetValue := 3 },
            contract_definition{ Id := "DAILY_MATCHES_05", Category := contract_category.Daily, Title := "Play 5 Matches", Description := "Complete 5 full 1v1 arena matches.", RequirementType := contract_requirement_type.MatchesPlayed, TargetValue := 5 },
            contract_definition{ Id := "DAILY_LOSSES_02", Category := contract_category.Daily, Title := "Lose 2 Matches", Description := "Complete 2 matches ending in defeat.", RequirementType := contract_requirement_type.Losses, TargetValue := 2 },
            contract_definition{ Id := "DAILY_FRAG_STREAK_03", Category := contract_category.Daily, Title := "Reach a 3-Frag Streak", Description := "Achieve an active 3-Frag streak without getting Fragged.", RequirementType := contract_requirement_type.FragStreak, TargetValue := 3 },
            contract_definition{ Id := "DAILY_WIN_STREAK_02", Category := contract_category.Daily, Title := "Win 2 Matches in a Row", Description := "Achieve a consecutive 2-match win streak.", RequirementType := contract_requirement_type.WinStreak, TargetValue := 2 },
            contract_definition{ Id := "DAILY_UNIQUE_03", Category := contract_category.Daily, Title := "Frag 3 Different Players", Description := "Frag 3 unique opponent players.", RequirementType := contract_requirement_type.UniqueOpponentFrags, TargetValue := 3 },

            # 8.2 Weekly Pool
            contract_definition{ Id := "WEEKLY_FRAG_50", Category := contract_category.Weekly, Title := "Frag 50 Players", Description := "Frag 50 opponent players during the weekly cycle.", RequirementType := contract_requirement_type.Frags, TargetValue := 50 },
            contract_definition{ Id := "WEEKLY_FRAG_75", Category := contract_category.Weekly, Title := "Frag 75 Players", Description := "Frag 75 opponent players during the weekly cycle.", RequirementType := contract_requirement_type.Frags, TargetValue := 75 },
            contract_definition{ Id := "WEEKLY_FRAG_100", Category := contract_category.Weekly, Title := "Frag 100 Players", Description := "Frag 100 opponent players during the weekly cycle.", RequirementType := contract_requirement_type.Frags, TargetValue := 100 },
            contract_definition{ Id := "WEEKLY_DEATH_25", Category := contract_category.Weekly, Title := "Get Fragged 25 Times", Description := "Get Fragged 25 times during arena matches.", RequirementType := contract_requirement_type.Deaths, TargetValue := 25 },
            contract_definition{ Id := "WEEKLY_WINS_10", Category := contract_category.Weekly, Title := "Win 10 Matches", Description := "Win 10 completed 1v1 arena matches.", RequirementType := contract_requirement_type.Wins, TargetValue := 10 },
            contract_definition{ Id := "WEEKLY_WINS_15", Category := contract_category.Weekly, Title := "Win 15 Matches", Description := "Win 15 completed 1v1 arena matches.", RequirementType := contract_requirement_type.Wins, TargetValue := 15 },
            contract_definition{ Id := "WEEKLY_MATCHES_20", Category := contract_category.Weekly, Title := "Play 20 Matches", Description := "Complete 20 full 1v1 arena matches.", RequirementType := contract_requirement_type.MatchesPlayed, TargetValue := 20 },
            contract_definition{ Id := "WEEKLY_MATCHES_25", Category := contract_category.Weekly, Title := "Play 25 Matches", Description := "Complete 25 full 1v1 arena matches.", RequirementType := contract_requirement_type.MatchesPlayed, TargetValue := 25 },
            contract_definition{ Id := "WEEKLY_LOSSES_10", Category := contract_category.Weekly, Title := "Lose 10 Matches", Description := "Complete 10 matches ending in defeat.", RequirementType := contract_requirement_type.Losses, TargetValue := 10 },
            contract_definition{ Id := "WEEKLY_FRAG_STREAK_10", Category := contract_category.Weekly, Title := "Reach a 10-Frag Streak", Description := "Achieve an active 10-Frag streak during the cycle.", RequirementType := contract_requirement_type.FragStreak, TargetValue := 10 },
            contract_definition{ Id := "WEEKLY_WIN_STREAK_03", Category := contract_category.Weekly, Title := "Win 3 Matches in a Row", Description := "Achieve a consecutive 3-match win streak.", RequirementType := contract_requirement_type.WinStreak, TargetValue := 3 },
            contract_definition{ Id := "WEEKLY_WIN_STREAK_05", Category := contract_category.Weekly, Title := "Win 5 Matches in a Row", Description := "Achieve a consecutive 5-match win streak.", RequirementType := contract_requirement_type.WinStreak, TargetValue := 5 },
            contract_definition{ Id := "WEEKLY_UNIQUE_10", Category := contract_category.Weekly, Title := "Frag 10 Different Players", Description := "Frag 10 unique opponent players.", RequirementType := contract_requirement_type.UniqueOpponentFrags, TargetValue := 10 },
            contract_definition{ Id := "WEEKLY_PLAYTIME_60", Category := contract_category.Weekly, Title := "Play for 1 Hour", Description := "Accumulate 60 minutes of active session play.", RequirementType := contract_requirement_type.PlaytimeMinutes, TargetValue := 60 },

            # 8.3 Milestone Pool (With Guaranteed Mastery Cosmetic Rewards)
            contract_definition{ Id := "MILESTONE_FRAG_100", Category := contract_category.Milestone, Title := "Frag 100 Players", Description := "Lifetime Milestone: Frag 100 opponent players.", RequirementType := contract_requirement_type.Frags, TargetValue := 100 },
            contract_definition{ Id := "MILESTONE_FRAG_250", Category := contract_category.Milestone, Title := "Frag 250 Players", Description := "Lifetime Milestone: Frag 250 opponent players.", RequirementType := contract_requirement_type.Frags, TargetValue := 250 },
            contract_definition{ Id := "MILESTONE_FRAG_500", Category := contract_category.Milestone, Title := "Frag 500 Players", Description := "Lifetime Milestone: Frag 500 opponent players.", RequirementType := contract_requirement_type.Frags, TargetValue := 500 },
            contract_definition{ Id := "MILESTONE_FRAG_1000", Category := contract_category.Milestone, Title := "Frag 1,000 Players", Description := "Lifetime Milestone: Frag 1,000 opponent players.", RequirementType := contract_requirement_type.Frags, TargetValue := 1000, RewardCosmeticId := "EM_SKULL_CROSS" },
            contract_definition{ Id := "MILESTONE_FRAG_2500", Category := contract_category.Milestone, Title := "Frag 2,500 Players", Description := "Lifetime Milestone: Frag 2,500 opponent players.", RequirementType := contract_requirement_type.Frags, TargetValue := 2500, RewardCosmeticId := "BK_NEON_GRID" },
            contract_definition{ Id := "MILESTONE_FRAG_5000", Category := contract_category.Milestone, Title := "Frag 5,000 Players", Description := "Lifetime Milestone: Frag 5,000 opponent players.", RequirementType := contract_requirement_type.Frags, TargetValue := 5000, RewardCosmeticId := "KE_ELECTRO_BURST" },
            contract_definition{ Id := "MILESTONE_FRAG_10000", Category := contract_category.Milestone, Title := "Frag 10,000 Players", Description := "Lifetime Milestone: Frag 10,000 opponent players.", RequirementType := contract_requirement_type.Frags, TargetValue := 10000, RewardCosmeticId := "EM_FRAG_APEX" },

            contract_definition{ Id := "MILESTONE_WIN_10", Category := contract_category.Milestone, Title := "Win 10 Matches", Description := "Lifetime Milestone: Win 10 completed matches.", RequirementType := contract_requirement_type.Wins, TargetValue := 10 },
            contract_definition{ Id := "MILESTONE_WIN_25", Category := contract_category.Milestone, Title := "Win 25 Matches", Description := "Lifetime Milestone: Win 25 completed matches.", RequirementType := contract_requirement_type.Wins, TargetValue := 25 },
            contract_definition{ Id := "MILESTONE_WIN_50", Category := contract_category.Milestone, Title := "Win 50 Matches", Description := "Lifetime Milestone: Win 50 completed matches.", RequirementType := contract_requirement_type.Wins, TargetValue := 50 },
            contract_definition{ Id := "MILESTONE_WIN_100", Category := contract_category.Milestone, Title := "Win 100 Matches", Description := "Lifetime Milestone: Win 100 completed matches.", RequirementType := contract_requirement_type.Wins, TargetValue := 100, RewardCosmeticId := "TI_ASSASSIN" },
            contract_definition{ Id := "MILESTONE_WIN_250", Category := contract_category.Milestone, Title := "Win 250 Matches", Description := "Lifetime Milestone: Win 250 completed matches.", RequirementType := contract_requirement_type.Wins, TargetValue := 250, RewardCosmeticId := "BP_NEON_CORE" },
            contract_definition{ Id := "MILESTONE_WIN_500", Category := contract_category.Milestone, Title := "Win 500 Matches", Description := "Lifetime Milestone: Win 500 completed matches.", RequirementType := contract_requirement_type.Wins, TargetValue := 500, RewardCosmeticId := "BK_APEX_GOLD" },

            contract_definition{ Id := "MILESTONE_DEATH_100", Category := contract_category.Milestone, Title := "Get Fragged 100 Times", Description := "Lifetime Milestone: Get Fragged 100 times.", RequirementType := contract_requirement_type.Deaths, TargetValue := 100 },
            contract_definition{ Id := "MILESTONE_DEATH_250", Category := contract_category.Milestone, Title := "Get Fragged 250 Times", Description := "Lifetime Milestone: Get Fragged 250 times.", RequirementType := contract_requirement_type.Deaths, TargetValue := 250 },
            contract_definition{ Id := "MILESTONE_DEATH_500", Category := contract_category.Milestone, Title := "Get Fragged 500 Times", Description := "Lifetime Milestone: Get Fragged 500 times.", RequirementType := contract_requirement_type.Deaths, TargetValue := 500 },
            contract_definition{ Id := "MILESTONE_DEATH_1000", Category := contract_category.Milestone, Title := "Get Fragged 1,000 Times", Description := "Lifetime Milestone: Get Fragged 1,000 times.", RequirementType := contract_requirement_type.Deaths, TargetValue := 1000 },
            contract_definition{ Id := "MILESTONE_SELFFRAG_10", Category := contract_category.Milestone, Title := "Self Frag 10 Times", Description := "Lifetime Milestone: Self Frag 10 times in combat.", RequirementType := contract_requirement_type.SelfFrags, TargetValue := 10 },
            contract_definition{ Id := "MILESTONE_SELFFRAG_25", Category := contract_category.Milestone, Title := "Self Frag 25 Times", Description := "Lifetime Milestone: Self Frag 25 times in combat.", RequirementType := contract_requirement_type.SelfFrags, TargetValue := 25 },
            contract_definition{ Id := "MILESTONE_SELFFRAG_50", Category := contract_category.Milestone, Title := "Self Frag 50 Times", Description := "Lifetime Milestone: Self Frag 50 times in combat.", RequirementType := contract_requirement_type.SelfFrags, TargetValue := 50, RewardCosmeticId := "TI_WARLORD" },
            contract_definition{ Id := "MILESTONE_FSTREAK_05", Category := contract_category.Milestone, Title := "Reach a 5-Frag Streak", Description := "Lifetime Milestone: Achieve a 5-Frag streak.", RequirementType := contract_requirement_type.FragStreak, TargetValue := 5 },
            contract_definition{ Id := "MILESTONE_FSTREAK_10", Category := contract_category.Milestone, Title := "Reach a 10-Frag Streak", Description := "Lifetime Milestone: Achieve a 10-Frag streak.", RequirementType := contract_requirement_type.FragStreak, TargetValue := 10 },
            contract_definition{ Id := "MILESTONE_FSTREAK_15", Category := contract_category.Milestone, Title := "Reach a 15-Frag Streak", Description := "Lifetime Milestone: Achieve a 15-Frag streak.", RequirementType := contract_requirement_type.FragStreak, TargetValue := 15 },
            contract_definition{ Id := "MILESTONE_FSTREAK_20", Category := contract_category.Milestone, Title := "Reach a 20-Frag Streak", Description := "Lifetime Milestone: Achieve a 20-Frag streak.", RequirementType := contract_requirement_type.FragStreak, TargetValue := 20, RewardCosmeticId := "KE_SOLAR_FLARE" },
            contract_definition{ Id := "MILESTONE_WSTREAK_03", Category := contract_category.Milestone, Title := "Win 3 Matches in a Row", Description := "Lifetime Milestone: Win 3 consecutive matches.", RequirementType := contract_requirement_type.WinStreak, TargetValue := 3 },
            contract_definition{ Id := "MILESTONE_WSTREAK_05", Category := contract_category.Milestone, Title := "Win 5 Matches in a Row", Description := "Lifetime Milestone: Win 5 consecutive matches.", RequirementType := contract_requirement_type.WinStreak, TargetValue := 5 },
            contract_definition{ Id := "MILESTONE_WSTREAK_10", Category := contract_category.Milestone, Title := "Win 10 Matches in a Row", Description := "Lifetime Milestone: Win 10 consecutive matches.", RequirementType := contract_requirement_type.WinStreak, TargetValue := 10, RewardCosmeticId := "TI_UNTOUCHABLE" },
            contract_definition{ Id := "MILESTONE_RANK_BRONZE", Category := contract_category.Milestone, Title := "Reach Bronze Rank", Description := "Reach Bronze Tier in competitive 1v1.", RequirementType := contract_requirement_type.RankTier, TargetValue := 1, RequiredRankTier := 1 },
            contract_definition{ Id := "MILESTONE_RANK_SILVER", Category := contract_category.Milestone, Title := "Reach Silver Rank", Description := "Reach Silver Tier in competitive 1v1.", RequirementType := contract_requirement_type.RankTier, TargetValue := 4, RequiredRankTier := 4 },
            contract_definition{ Id := "MILESTONE_RANK_GOLD", Category := contract_category.Milestone, Title := "Reach Gold Rank", Description := "Reach Gold Tier in competitive 1v1.", RequirementType := contract_requirement_type.RankTier, TargetValue := 7, RequiredRankTier := 7 },
            contract_definition{ Id := "MILESTONE_RANK_PLATINUM", Category := contract_category.Milestone, Title := "Reach Platinum Rank", Description := "Reach Platinum Tier in competitive 1v1.", RequirementType := contract_requirement_type.RankTier, TargetValue := 10, RequiredRankTier := 10 },
            contract_definition{ Id := "MILESTONE_RANK_DIAMOND", Category := contract_category.Milestone, Title := "Reach Diamond Rank", Description := "Reach Diamond Tier in competitive 1v1.", RequirementType := contract_requirement_type.RankTier, TargetValue := 13, RequiredRankTier := 13 },
            contract_definition{ Id := "MILESTONE_RANK_ELITE", Category := contract_category.Milestone, Title := "Reach Elite Rank", Description := "Reach Elite Tier in competitive 1v1.", RequirementType := contract_requirement_type.RankTier, TargetValue := 16, RequiredRankTier := 16 },
            contract_definition{ Id := "MILESTONE_RANK_CHAMPION", Category := contract_category.Milestone, Title := "Reach Champion Rank", Description := "Reach Champion Tier in competitive 1v1.", RequirementType := contract_requirement_type.RankTier, TargetValue := 17, RequiredRankTier := 17, RewardCosmeticId := "EM_CYBER_CROWN" },
            contract_definition{ Id := "MILESTONE_RANK_UNREAL", Category := contract_category.Milestone, Title := "Reach Unreal Rank", Description := "Reach Unreal Tier in competitive 1v1.", RequirementType := contract_requirement_type.RankTier, TargetValue := 18, RequiredRankTier := 18, RewardCosmeticId := "BP_DARK_SHROUD" },
            contract_definition{ Id := "MILESTONE_RANK_FRAGMASTER", Category := contract_category.Milestone, Title := "Reach Frag Master", Description := "Reach the apex Frag Master Tier.", RequirementType := contract_requirement_type.RankTier, TargetValue := 19, RequiredRankTier := 19, RewardCosmeticId := "BP_CHRONO_WINGS" }

    GetCurrentDailyCycleId()<transacts> : int =
        EpochSeconds := GetSecondsSinceEpoch()
        if (Day := Floor[EpochSeconds / 86400.0]):
            return Day
        return 0

    GetCurrentWeeklyCycleId()<transacts> : int =
        EpochSeconds := GetSecondsSinceEpoch()
        if (Week := Floor[EpochSeconds / 604800.0]):
            return Week
        return 0

    FindDefinition<public>(Id : string)<transacts> : ?contract_definition =
        for (Def : GetContractDefinitions(), Def.Id = Id):
            return option { Def }
        return false

    GetOrInitializePlayerContracts<public>(Agent : agent) : player_persistable_contracts =
        if (Data := ActiveContractsMap[Agent]):
            return Data
        InitializePlayerContracts(Agent)
        if (Data := ActiveContractsMap[Agent]):
            return Data
        return player_persistable_contracts{}

    InitializePlayerContracts<public>(Agent : agent) : void =
        if (Plr := player[Agent]):
            CurrentDaily := GetCurrentDailyCycleId()
            CurrentWeekly := GetCurrentWeeklyCycleId()

            Profile := GetPlayerProfile(Plr)
            var ContractsData : player_persistable_contracts = Profile.Contracts

            Stats := if (S := StatsManager.GetPlayerStats(Agent)?) then S else player_persistable_stats{}

            # Check Daily Cycle
            var NewDailyEntries : []persisted_contract_entry = ContractsData.ActiveDailyContracts
            var NewDailyCycle : int = ContractsData.DailyCycleId
            var NewVictims : []string = ContractsData.UniqueVictimIds
            if (ContractsData.DailyCycleId <> CurrentDaily or ContractsData.ActiveDailyContracts.Length <> 3):
                set NewDailyCycle = CurrentDaily
                set NewDailyEntries = RollNewRotatingTrio(contract_category.Daily, Stats)
                set NewVictims = array{}

            # Check Weekly Cycle
            var NewWeeklyEntries : []persisted_contract_entry = ContractsData.ActiveWeeklyContracts
            var NewWeeklyCycle : int = ContractsData.WeeklyCycleId
            if (ContractsData.WeeklyCycleId <> CurrentWeekly or ContractsData.ActiveWeeklyContracts.Length <> 3):
                set NewWeeklyCycle = CurrentWeekly
                set NewWeeklyEntries = RollNewRotatingTrio(contract_category.Weekly, Stats)

            UpdatedData := player_persistable_contracts:
                DailyCycleId := NewDailyCycle
                ActiveDailyContracts := NewDailyEntries
                WeeklyCycleId := NewWeeklyCycle
                ActiveWeeklyContracts := NewWeeklyEntries
                CompletedMilestoneIds := ContractsData.CompletedMilestoneIds
                UniqueVictimIds := NewVictims
                TrackedPlaytimeSeconds := ContractsData.TrackedPlaytimeSeconds

            if. set ActiveContractsMap[Agent] = UpdatedData
            SavePlayerContracts(Plr)

            EvaluateAllContractsForPlayer(Agent)

    RollNewRotatingTrio(Category : contract_category, Stats : player_persistable_stats)<transacts> : []persisted_contract_entry =
        var CategoryPool : []contract_definition = array{}
        for (Def : GetContractDefinitions(), Def.Category = Category):
            set CategoryPool += array{ Def }

        Shuffled := Shuffle(CategoryPool)
        var Result : []persisted_contract_entry = array{}
        for (I := 0..2):
            if (Def := Shuffled[I]):
                Baseline := GetStatBaselineForRequirement(Def.RequirementType, Stats)
                Entry := persisted_contract_entry:
                    Id := Def.Id
                    BaselineValue := Baseline
                    CustomEventProgress := 0
                    IsCompleted := false
                set Result += array{ Entry }
        return Result

    GetStatBaselineForRequirement(Req : contract_requirement_type, Stats : player_persistable_stats)<transacts> : int =
        case (Req):
            contract_requirement_type.Frags => Stats.Kills
            contract_requirement_type.Deaths => Stats.Deaths
            contract_requirement_type.SelfFrags => Stats.Suicides
            contract_requirement_type.Wins => Stats.Wins
            contract_requirement_type.Losses => Stats.Losses
            contract_requirement_type.MatchesPlayed => Stats.Wins + Stats.Losses
            contract_requirement_type.FragStreak => 0
            contract_requirement_type.WinStreak => 0
            contract_requirement_type.RankTier => 0
            contract_requirement_type.UniqueOpponentFrags => 0
            contract_requirement_type.PlaytimeMinutes => 0

    SavePlayerContracts(Plr : player) : void =
        if (Data := ActiveContractsMap[Plr]):
            SavePlayerContractsToProfile(Plr, Data)

    SnapshotMatchPreState<public>(Agent : agent) : void =
        if (Data := ActiveContractsMap[Agent]):
            if. set MatchPreStateMap[Agent] = Data

    CompilePostMatchSummary<public>(Agent : agent) : void =
        if (PreState := MatchPreStateMap[Agent], PostState := ActiveContractsMap[Agent]):
            Stats := if (S := StatsManager.GetPlayerStats(Agent)?) then S else player_persistable_stats{}
            var Summaries : []contract_match_summary = array{}

            for (PostEntry : PostState.ActiveDailyContracts):
                if (Def := FindDefinition(PostEntry.Id)?):
                    PrevProgress := CalculateProgressForEntry(Def, PreState, Stats, PostEntry.Id)
                    CurrProgress := CalculateProgressForEntry(Def, PostState, Stats, PostEntry.Id)
                    if (CurrProgress > PrevProgress or PostEntry.IsCompleted = true):
                        Delta := CurrProgress - PrevProgress
                        WasCompletedNow := if (CurrProgress >= Def.TargetValue, PrevProgress < Def.TargetValue) then true else false
                        Summary := contract_match_summary:
                            ContractId := Def.Id
                            Title := Def.Title
                            Category := Def.Category
                            PreviousProgress := PrevProgress
                            NewProgress := CurrProgress
                            TargetProgress := Def.TargetValue
                            ProgressDelta := Delta
                            IsCompleted := PostEntry.IsCompleted
                            WasCompletedInMatch := WasCompletedNow
                            RewardCosmeticId := Def.RewardCosmeticId
                        set Summaries += array{ Summary }

            for (PostEntry : PostState.ActiveWeeklyContracts):
                if (Def := FindDefinition(PostEntry.Id)?):
                    PrevProgress := CalculateProgressForEntry(Def, PreState, Stats, PostEntry.Id)
                    CurrProgress := CalculateProgressForEntry(Def, PostState, Stats, PostEntry.Id)
                    if (CurrProgress > PrevProgress or PostEntry.IsCompleted = true):
                        Delta := CurrProgress - PrevProgress
                        WasCompletedNow := if (CurrProgress >= Def.TargetValue, PrevProgress < Def.TargetValue) then true else false
                        Summary := contract_match_summary:
                            ContractId := Def.Id
                            Title := Def.Title
                            Category := Def.Category
                            PreviousProgress := PrevProgress
                            NewProgress := CurrProgress
                            TargetProgress := Def.TargetValue
                            ProgressDelta := Delta
                            IsCompleted := PostEntry.IsCompleted
                            WasCompletedInMatch := WasCompletedNow
                            RewardCosmeticId := Def.RewardCosmeticId
                        set Summaries += array{ Summary }

            for (Def : GetContractDefinitions(), Def.Category = contract_category.Milestone):
                PrevCompleted := IsMilestoneIdCompleted(PreState.CompletedMilestoneIds, Def.Id)
                CurrCompleted := IsMilestoneIdCompleted(PostState.CompletedMilestoneIds, Def.Id)
                if (CurrCompleted = true, PrevCompleted = false):
                    Summary := contract_match_summary:
                        ContractId := Def.Id
                        Title := Def.Title
                        Category := Def.Category
                        PreviousProgress := Def.TargetValue - 1
                        NewProgress := Def.TargetValue
                        TargetProgress := Def.TargetValue
                        ProgressDelta := 1
                        IsCompleted := true
                        WasCompletedInMatch := true
                        RewardCosmeticId := Def.RewardCosmeticId
                    set Summaries += array{ Summary }

            if. set MatchSummaryMap[Agent] = Summaries

    GetPostMatchSummary<public>(Agent : agent)<transacts> : []contract_match_summary =
        if (Summary := MatchSummaryMap[Agent]):
            return Summary
        return array{}

    ClearMatchSummary<public>(Agent : agent) : void =
        var NewSummaryMap : [agent][]contract_match_summary = map{}
        for (Key -> Val : MatchSummaryMap, Key <> Agent):
            if. set NewSummaryMap[Key] = Val
        set MatchSummaryMap = NewSummaryMap

    HandleKillfeedEvent(Payload : tuple(?agent, agent, logic)) : void =
        KillerOpt := Payload(0)
        Victim := Payload(1)
        IsSuicide := Payload(2)

        if (Killer := KillerOpt?, Killer <> Victim, not IsSuicide?):
            RecordFragProgress(Killer, Victim)
        else RecordSelfFragProgress(Victim)

    RecordFragProgress(Killer : agent, Victim : agent) : void =
        if (Plr := player[Killer], Data := ActiveContractsMap[Killer]):
            var AlreadyFragged : logic = false
            for (VId : Data.UniqueVictimIds):
                set AlreadyFragged = true

            var NewVictims : []string = Data.UniqueVictimIds
            var AddedUnique : logic = false
            if (AlreadyFragged = false):
                set AddedUnique = true

            NewDaily := UpdateEntriesForRequirement(Data.ActiveDailyContracts, contract_requirement_type.UniqueOpponentFrags, 1, AddedUnique)
            NewWeekly := UpdateEntriesForRequirement(Data.ActiveWeeklyContracts, contract_requirement_type.UniqueOpponentFrags, 1, AddedUnique)

            UpdatedData := player_persistable_contracts:
                DailyCycleId := Data.DailyCycleId
                ActiveDailyContracts := NewDaily
                WeeklyCycleId := Data.WeeklyCycleId
                ActiveWeeklyContracts := NewWeekly
                CompletedMilestoneIds := Data.CompletedMilestoneIds
                UniqueVictimIds := NewVictims
                TrackedPlaytimeSeconds := Data.TrackedPlaytimeSeconds

            if. set ActiveContractsMap[Killer] = UpdatedData
            SavePlayerContracts(Plr)
            EvaluateAllContractsForPlayer(Killer)

    RecordDeathProgress(Victim : agent) : void =
        EvaluateAllContractsForPlayer(Victim)

    RecordSelfFragProgress(Victim : agent) : void =
        EvaluateAllContractsForPlayer(Victim)

    HandlePlayerStatsUpdated(Payload : tuple(agent, player_persistable_stats)) : void =
        Agent := Payload(0)
        EvaluateAllContractsForPlayer(Agent)

    PlaytimeTrackingLoop()<suspends> : void =
        loop:
            Sleep(60.0)
            CurrentTime := GetSimulationElapsedTime()
            DeltaSeconds := CurrentTime - LastPlaytimeCheckTime
            set LastPlaytimeCheckTime = CurrentTime

            for (P : GetPlayspace().GetPlayers(), P.IsActive[]):
                if (Data := ActiveContractsMap[P]):
                    NewPlaytime := Data.TrackedPlaytimeSeconds + DeltaSeconds
                    UpdatedData := player_persistable_contracts:
                        DailyCycleId := Data.DailyCycleId
                        ActiveDailyContracts := Data.ActiveDailyContracts
                        WeeklyCycleId := Data.WeeklyCycleId
                        ActiveWeeklyContracts := Data.ActiveWeeklyContracts
                        CompletedMilestoneIds := Data.CompletedMilestoneIds
                        UniqueVictimIds := Data.UniqueVictimIds
                        TrackedPlaytimeSeconds := NewPlaytime

                    if. set ActiveContractsMap[P] = UpdatedData
                    EvaluateAllContractsForPlayer(P)

    UpdateEntriesForRequirement(Entries : []persisted_contract_entry, Req : contract_requirement_type, Amount : int, Condition : logic)<transacts> : []persisted_contract_entry =
        if (Condition = false) then return Entries
        var Result : []persisted_contract_entry = array{}
        for (Entry : Entries):
            if (Def := FindDefinition(Entry.Id)?, Def.RequirementType = Req):
                NewProg := Entry.CustomEventProgress + Amount
                NewCompleted := if (NewProg >= Def.TargetValue) then true else Entry.IsCompleted
                UpdatedEntry := persisted_contract_entry:
                    Id := Entry.Id
                    BaselineValue := Entry.BaselineValue
                    CustomEventProgress := NewProg
                    IsCompleted := NewCompleted
                set Result += array{ UpdatedEntry }
            else:
                set Result += array{ Entry }
        return Result

    EvaluateAllContractsForPlayer(Agent : agent) : void =
        if (Plr := player[Agent], Data := ActiveContractsMap[Agent]):
            Stats := if (S := StatsManager.GetPlayerStats(Agent)?) then S else player_persistable_stats{}
            var NewDaily : []persisted_contract_entry = array{}
            var NewWeekly : []persisted_contract_entry = array{}
            var NewMilestones : []string = Data.CompletedMilestoneIds
            var StateChanged : logic = false

            # 1. Evaluate Daily Contracts (+25 Cybercash)
            for (Entry : Data.ActiveDailyContracts):
                if (Def := FindDefinition(Entry.Id)?):
                    CurrentProg := CalculateProgressForEntry(Def, Data, Stats, Entry.Id)
                    IsComplete := if (CurrentProg >= Def.TargetValue) then true else false
                    if (IsComplete = true, Entry.IsCompleted = false):
                        set StateChanged = true
                        ContractCompletedEvent.Signal((Agent, contract_category.Daily))
                        EconomyManager.AwardDailyQuestCybercash(Agent)
                    NewEntry := persisted_contract_entry:
                        Id := Entry.Id
                        BaselineValue := Entry.BaselineValue
                        CustomEventProgress := Entry.CustomEventProgress
                        IsCompleted := IsComplete
                    set NewDaily += array{ NewEntry }
                else:
                    set NewDaily += array{ Entry }

            # 2. Evaluate Weekly Contracts (+50 Cybercash)
            for (Entry : Data.ActiveWeeklyContracts):
                if (Def := FindDefinition(Entry.Id)?):
                    CurrentProg := CalculateProgressForEntry(Def, Data, Stats, Entry.Id)
                    IsComplete := if (CurrentProg >= Def.TargetValue) then true else false
                    if (IsComplete = true, Entry.IsCompleted = false):
                        set StateChanged = true
                        ContractCompletedEvent.Signal((Agent, contract_category.Weekly))
                        EconomyManager.AwardWeeklyQuestCybercash(Agent)
                    NewEntry := persisted_contract_entry:
                        Id := Entry.Id
                        BaselineValue := Entry.BaselineValue
                        CustomEventProgress := Entry.CustomEventProgress
                        IsCompleted := IsComplete
                    set NewWeekly += array{ NewEntry }
                else:
                    set NewWeekly += array{ Entry }

            # 3. Evaluate Milestones (+10 to +50 Cybercash & Milestone Mastery Cosmetic Unlocks)
            Rank := StatsManager.ResolveRankFromElo(Stats.Elo)
            for (Def : GetContractDefinitions(), Def.Category = contract_category.Milestone):
                if (IsMilestoneIdCompleted(NewMilestones, Def.Id) = false):
                    MilestoneProg := CalculateMilestoneProgress(Def, Stats, Rank)
                    if (MilestoneProg >= Def.TargetValue):
                        set NewMilestones += array{ Def.Id }
                        set StateChanged = true
                        ContractCompletedEvent.Signal((Agent, contract_category.Milestone))
                        EconomyManager.AwardMilestoneCybercash(Agent, Def.TargetValue)

                        # Grant single specified cosmetic reward if configured on milestone
                        if (Def.RewardCosmeticId <> ""):
                            CustomizationManager.UnlockItem(Agent, Def.RewardCosmeticId)

            if (StateChanged = true):
                UpdatedData := player_persistable_contracts:
                    DailyCycleId := Data.DailyCycleId
                    ActiveDailyContracts := NewDaily
                    WeeklyCycleId := Data.WeeklyCycleId
                    ActiveWeeklyContracts := NewWeekly
                    CompletedMilestoneIds := NewMilestones
                    UniqueVictimIds := Data.UniqueVictimIds
                    TrackedPlaytimeSeconds := Data.TrackedPlaytimeSeconds

                if. set ActiveContractsMap[Agent] = UpdatedData
                SavePlayerContracts(Plr)
                ContractsUpdatedEvent.Signal(Agent)

    CalculateProgressForEntry(Def : contract_definition, Data : player_persistable_contracts, Stats : player_persistable_stats, EntryId : string)<transacts> : int =
        var Baseline : int = 0
        var CustomProg : int = 0
        for (E : Data.ActiveDailyContracts, E.Id = EntryId):
            set Baseline = E.BaselineValue
            set CustomProg = E.CustomEventProgress
        for (E : Data.ActiveWeeklyContracts, E.Id = EntryId):
            set Baseline = E.BaselineValue
            set CustomProg = E.CustomEventProgress

        case (Def.RequirementType):
            contract_requirement_type.Frags =>
                if (Stats.Kills >= Baseline) then Stats.Kills - Baseline else 0
            contract_requirement_type.Deaths =>
                if (Stats.Deaths >= Baseline) then Stats.Deaths - Baseline else 0
            contract_requirement_type.SelfFrags =>
                if (Stats.Suicides >= Baseline) then Stats.Suicides - Baseline else 0
            contract_requirement_type.Wins =>
                if (Stats.Wins >= Baseline) then Stats.Wins - Baseline else 0
            contract_requirement_type.Losses =>
                if (Stats.Losses >= Baseline) then Stats.Losses - Baseline else 0
            contract_requirement_type.MatchesPlayed =>
                TotalMatches := Stats.Wins + Stats.Losses
                if (TotalMatches >= Baseline) then TotalMatches - Baseline else 0
            contract_requirement_type.FragStreak =>
                Stats.CurrentKillStreak
            contract_requirement_type.WinStreak =>
                Stats.CurrentWinStreak
            contract_requirement_type.RankTier =>
                0
            contract_requirement_type.UniqueOpponentFrags =>
                CustomProg
            contract_requirement_type.PlaytimeMinutes =>
                if (M := Floor[Data.TrackedPlaytimeSeconds / 60.0]) then M else 0

    CalculateMilestoneProgress(Def : contract_definition, Stats : player_persistable_stats, Rank : rank_resolution)<transacts> : int =
        case (Def.RequirementType):
            contract_requirement_type.Frags => Stats.Kills
            contract_requirement_type.Deaths => Stats.Deaths
            contract_requirement_type.SelfFrags => Stats.Suicides
            contract_requirement_type.Wins => Stats.Wins
            contract_requirement_type.Losses => Stats.Losses
            contract_requirement_type.MatchesPlayed => Stats.Wins + Stats.Losses
            contract_requirement_type.FragStreak => Stats.MaxKillStreak
            contract_requirement_type.WinStreak => Stats.MaxWinStreak
            contract_requirement_type.RankTier =>
                if (Rank.Tier >= Def.RequiredRankTier) then Def.TargetValue else Rank.Tier
            contract_requirement_type.UniqueOpponentFrags => 0
            contract_requirement_type.PlaytimeMinutes => 0

    IsMilestoneIdCompleted(CompletedList : []string, TargetId : string)<transacts> : logic =
        for (Id : CompletedList, Id = TargetId):
            return true
        return false

    GetActiveDailyContracts<public>(Agent : agent) : []contract_ui_data =
        Data := GetOrInitializePlayerContracts(Agent)
        Stats := if (S := StatsManager.GetPlayerStats(Agent)?) then S else player_persistable_stats{}
        var Results : []contract_ui_data = array{}
        for (Entry : Data.ActiveDailyContracts):
            if (Def := FindDefinition(Entry.Id)?):
                Prog := CalculateProgressForEntry(Def, Data, Stats, Entry.Id)
                ClampedProg := if (Prog > Def.TargetValue) then Def.TargetValue else Prog
                Scalar := if (Def.TargetValue > 0) then (ClampedProg * 1.0) / (Def.TargetValue * 1.0) else 1.0
                PercentInt := if (PI := Round[Scalar * 100.0]) then PI else 0
                UIData := contract_ui_data:
                    Id := Def.Id
                    Category := contract_category.Daily
                    Title := Def.Title
                    Description := Def.Description
                    CurrentProgress := ClampedProg
                    TargetProgress := Def.TargetValue
                    ProgressScalar := Scalar
                    ProgressPercent := "{PercentInt}%"
                    IsCompleted := Entry.IsCompleted
                    RewardCosmeticId := Def.RewardCosmeticId
                set Results += array{ UIData }
        return Results

    GetActiveWeeklyContracts<public>(Agent : agent) : []contract_ui_data =
        Data := GetOrInitializePlayerContracts(Agent)
        Stats := if (S := StatsManager.GetPlayerStats(Agent)?) then S else player_persistable_stats{}
        var Results : []contract_ui_data = array{}
        for (Entry : Data.ActiveWeeklyContracts):
            if (Def := FindDefinition(Entry.Id)?):
                Prog := CalculateProgressForEntry(Def, Data, Stats, Entry.Id)
                ClampedProg := if (Prog > Def.TargetValue) then Def.TargetValue else Prog
                Scalar := if (Def.TargetValue > 0) then (ClampedProg * 1.0) / (Def.TargetValue * 1.0) else 1.0
                PercentInt := if (PI := Round[Scalar * 100.0]) then PI else 0
                UIData := contract_ui_data:
                    Id := Def.Id
                    Category := contract_category.Weekly
                    Title := Def.Title
                    Description := Def.Description
                    CurrentProgress := ClampedProg
                    TargetProgress := Def.TargetValue
                    ProgressScalar := Scalar
                    ProgressPercent := "{PercentInt}%"
                    IsCompleted := Entry.IsCompleted
                    RewardCosmeticId := Def.RewardCosmeticId
                set Results += array{ UIData }
        return Results

    GetMilestoneContracts<public>(Agent : agent) : []contract_ui_data =
        Data := GetOrInitializePlayerContracts(Agent)
        Stats := if (S := StatsManager.GetPlayerStats(Agent)?) then S else player_persistable_stats{}
        Rank := StatsManager.ResolveRankFromElo(Stats.Elo)
        var Results : []contract_ui_data = array{}
        for (Def : GetContractDefinitions(), Def.Category = contract_category.Milestone):
            IsComplete := IsMilestoneIdCompleted(Data.CompletedMilestoneIds, Def.Id)
            RawProg := CalculateMilestoneProgress(Def, Stats, Rank)
            ClampedProg := if (RawProg > Def.TargetValue) then Def.TargetValue else RawProg
            Scalar := if (Def.TargetValue > 0) then (ClampedProg * 1.0) / (Def.TargetValue * 1.0) else 1.0
            PercentInt := if (PI := Round[Scalar * 100.0]) then PI else 0
            UIData := contract_ui_data:
                Id := Def.Id
                Category := contract_category.Milestone
                Title := Def.Title
                Description := Def.Description
                CurrentProgress := ClampedProg
                TargetProgress := Def.TargetValue
                ProgressScalar := Scalar
                ProgressPercent := "{PercentInt}%"
                IsCompleted := IsComplete
                RewardCosmeticId := Def.RewardCosmeticId
            set Results += array{ UIData }
        return Results