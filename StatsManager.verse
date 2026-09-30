using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Verse }
using { /Fortnite.com/Characters }
using { /Verse.org/Assets }

rank_tier_config := class<concrete>:
    @editable RankName : string = "Unranked"
    @editable MinimumElo : float = 0.0
    @editable IconType : rank_icon_type = rank_icon_type.Unranked

stats_calc_settings := class<concrete>():
    @editable RankTiers : []rank_tier_config = array{}
    @editable:
        ToolTip := EloBaseInfo
    BaseElo : float = 1000.0

    @editable:
        ToolTip := BaseGainInfo
    BaseGain : float = 25.0

    @editable:
        ToolTip := BaseLossInfo
    BaseLoss : float = 20.0

    @editable:
        ToolTip := WinStreakThresholdInfo
    WinStreakThreshold : int = 2

    @editable:
        ToolTip := WinStreakMultiplierInfo
    WinStreakMultiplier : float = 1.2

    @editable:
        ToolTip := LossDampingThresholdInfo
    LossDampingThreshold : int = 2

    @editable:
        ToolTip := LossDampInfo
    LossMitigationFactor : float = 0.5

    @editable:
        ToolTip := SuicideEloPenaltyInfo
    SuicideEloPenalty : float = 5.0

    @editable:
        ToolTip := EliminationEloGainInfo
    EliminationEloGain : float = 0.0

    @editable:
        ToolTip := HeadshotEloGainInfo
    HeadshotEloGain : float = 0.0

stats_manager := class(creative_device):
    @editable:
        ToolTip := EloBaseInfo
    RankSettings : stats_calc_settings = stats_calc_settings{}

    @editable:
        ToolTip := EconomyManagerInfo
    EconomyManager : economy_manager = economy_manager{}

    var SessionStats : [agent]player_stats = map{}
    var LastMatchTransitions : [agent]match_rank_transition = map{}

    PlayerStatsUpdatedEvent<public> : event(tuple(agent, player_persistable_stats)) = event(tuple(agent, player_persistable_stats)){}
    KillfeedEvent<public> : event(tuple(?agent, agent, logic)) = event(tuple(?agent, agent, logic)){}
    MatchFinalizedEvent<public> : event(tuple(agent, agent)) = event(tuple(agent, agent)){}

    OnBegin<override>()<suspends> : void =
        GetPlayspace().PlayerAddedEvent().Subscribe(InitializePlayer)
        GetPlayspace().PlayerRemovedEvent().Subscribe(OnPlayerRemoved)
        for (P : GetPlayspace().GetPlayers()) do InitializePlayer(P)

    OnPlayerRemoved(P : player) : void =
        var NewSessionStats : [agent]player_stats = map{}
        for (Key -> Val : SessionStats, Key <> P):
            if. set NewSessionStats[Key] = Val
        set SessionStats = NewSessionStats

        var NewTransitions : [agent]match_rank_transition = map{}
        for (Key -> Val : LastMatchTransitions, Key <> P):
            if. set NewTransitions[Key] = Val
        set LastMatchTransitions = NewTransitions

    InitializePlayer(Agent : agent) : void =
        if (Player := player[Agent]):
            Profile := GetPlayerProfile(Player)
            var LoadedStats : player_persistable_stats = Profile.Stats
            if (LoadedStats.Elo <= 0.0):
                set LoadedStats = player_persistable_stats{Elo := RankSettings.BaseElo}

            if (not SessionStats[Agent]):
                NewStats := player_stats{Player := Agent, Current := LoadedStats, JoinTime := GetSimulationElapsedTime()}
                if. set SessionStats[Agent] = NewStats

    SavePlayerStats(Agent : agent) : void =
        if (Player := player[Agent], Stats := SessionStats[Agent]):
            SavePlayerStatsToProfile(Player, Stats.Current)
            PlayerStatsUpdatedEvent.Signal((Agent, Stats.Current))

    GetPlayerStats<public>(Agent : agent)<transacts> : ?player_persistable_stats =
        if (Stats := SessionStats[Agent]):
            return option { Stats.Current }
        return false

    RecordElimination<public>(Killer : agent, Victim : agent) : void =
        if (KStats := SessionStats[Killer]):
            Old := KStats.Current
            NewKillStreak := Old.CurrentKillStreak + 1
            NewMaxKillStreak := if (NewKillStreak > Old.MaxKillStreak) then NewKillStreak else Old.MaxKillStreak
            set KStats.Current = player_persistable_stats:
                Kills := Old.Kills + 1,
                Deaths := Old.Deaths,
                Wins := Old.Wins,
                Losses := Old.Losses,
                Headshots := Old.Headshots,
                Suicides := Old.Suicides,
                Elo := Old.Elo + RankSettings.EliminationEloGain,
                WinVelocity := Old.WinVelocity,
                LossDamping := Old.LossDamping,
                CurrentKillStreak := NewKillStreak,
                MaxKillStreak := NewMaxKillStreak,
                CurrentWinStreak := Old.CurrentWinStreak,
                MaxWinStreak := Old.MaxWinStreak
            SavePlayerStats(Killer)

        if (VStats := SessionStats[Victim]):
            Old := VStats.Current
            set VStats.Current = player_persistable_stats:
                Kills := Old.Kills,
                Deaths := Old.Deaths + 1,
                Wins := Old.Wins,
                Losses := Old.Losses,
                Headshots := Old.Headshots,
                Suicides := Old.Suicides,
                Elo := Old.Elo,
                WinVelocity := Old.WinVelocity,
                LossDamping := Old.LossDamping,
                CurrentKillStreak := 0,
                MaxKillStreak := Old.MaxKillStreak,
                CurrentWinStreak := Old.CurrentWinStreak,
                MaxWinStreak := Old.MaxWinStreak
            SavePlayerStats(Victim)

        KillfeedEvent.Signal((option { Killer }, Victim, false))

    RecordSuicide<public>(Agent : agent) : void =
        if (Stats := SessionStats[Agent]):
            Old := Stats.Current
            NewElo := if (Old.Elo - RankSettings.SuicideEloPenalty >= 0.0) then Old.Elo - RankSettings.SuicideEloPenalty else 0.0
            set Stats.Current = player_persistable_stats:
                Suicides := Old.Suicides + 1,
                Deaths := Old.Deaths + 1,
                Kills := Old.Kills,
                Wins := Old.Wins,
                Losses := Old.Losses,
                Headshots := Old.Headshots,
                Elo := NewElo,
                WinVelocity := 0,
                LossDamping := Old.LossDamping,
                CurrentKillStreak := 0,
                MaxKillStreak := Old.MaxKillStreak,
                CurrentWinStreak := Old.CurrentWinStreak,
                MaxWinStreak := Old.MaxWinStreak
            SavePlayerStats(Agent)

        KillfeedEvent.Signal((false, Agent, true))

    RecordHeadshot<public>(Agent : agent) : void =
        if (Stats := SessionStats[Agent]):
            Old := Stats.Current
            set Stats.Current = player_persistable_stats:
                Headshots := Old.Headshots + 1,
                Kills := Old.Kills,
                Deaths := Old.Deaths,
                Wins := Old.Wins,
                Losses := Old.Losses,
                Suicides := Old.Suicides,
                Elo := Old.Elo + RankSettings.HeadshotEloGain,
                WinVelocity := Old.WinVelocity,
                LossDamping := Old.LossDamping,
                CurrentKillStreak := Old.CurrentKillStreak,
                MaxKillStreak := Old.MaxKillStreak,
                CurrentWinStreak := Old.CurrentWinStreak,
                MaxWinStreak := Old.MaxWinStreak
            SavePlayerStats(Agent)

    DevRankDown<public>(Agent : agent) : void =
        if (Stats := SessionStats[Agent]):
            CurrentRank := ResolveRankFromElo(Stats.Current.Elo)
            if (CurrentRank.Tier > 0, PreviousTier := RankSettings.RankTiers[CurrentRank.Tier - 1]):
                Old := Stats.Current
                set Stats.Current = player_persistable_stats:
                    Headshots := Old.Headshots,
                    Kills := Old.Kills,
                    Deaths := Old.Deaths,
                    Wins := Old.Wins,
                    Losses := Old.Losses,
                    Suicides := Old.Suicides,
                    Elo := PreviousTier.MinimumElo,
                    WinVelocity := Old.WinVelocity,
                    LossDamping := Old.LossDamping,
                    CurrentKillStreak := Old.CurrentKillStreak,
                    MaxKillStreak := Old.MaxKillStreak,
                    CurrentWinStreak := Old.CurrentWinStreak,
                    MaxWinStreak := Old.MaxWinStreak
                SavePlayerStats(Agent)

    DevRankUp<public>(Agent : agent) : void =
        if (Stats := SessionStats[Agent]):
            CurrentRank := ResolveRankFromElo(Stats.Current.Elo)
            if (NextTier := RankSettings.RankTiers[CurrentRank.Tier + 1]):
                Old := Stats.Current
                set Stats.Current = player_persistable_stats:
                    Headshots := Old.Headshots,
                    Kills := Old.Kills,
                    Deaths := Old.Deaths,
                    Wins := Old.Wins,
                    Losses := Old.Losses,
                    Suicides := Old.Suicides,
                    Elo := NextTier.MinimumElo,
                    WinVelocity := Old.WinVelocity,
                    LossDamping := Old.LossDamping,
                    CurrentKillStreak := Old.CurrentKillStreak,
                    MaxKillStreak := Old.MaxKillStreak,
                    CurrentWinStreak := Old.CurrentWinStreak,
                    MaxWinStreak := Old.MaxWinStreak
                SavePlayerStats(Agent)

    GetRankProgress<public>(Elo : float)<transacts> : tuple(float, string) =
        CurrentRank := ResolveRankFromElo(Elo)
        TierCount := RankSettings.RankTiers.Length
        if (TierCount > 0):
            if (CurrentRank.Tier < TierCount - 1):
                if (CurrTier := RankSettings.RankTiers[CurrentRank.Tier], NextTier := RankSettings.RankTiers[CurrentRank.Tier + 1]):
                    Range := NextTier.MinimumElo - CurrTier.MinimumElo
                    if (Range > 0.0):
                        RawProgress := (Elo - CurrTier.MinimumElo) / Range
                        ClampedProgress := Clamp(RawProgress, 0.0, 1.0)
                        if (RoundedInt := Round[ClampedProgress * 100.0]):
                            return (ClampedProgress, "{RoundedInt}%")
                        return (ClampedProgress, "0%")
            else return (1.0, "100%")
        return (0.0, "0%")

    Finalize1v1MatchStats<public>(Winner : agent, Loser : agent) : void =
        # Process Winner
        if (WStats := SessionStats[Winner]):
            OldW := WStats.Current
            OldRankW := ResolveRankFromElo(OldW.Elo)
            OldProgW := GetRankProgress(OldW.Elo)

            var FinalGain : float = RankSettings.BaseGain
            if (OldW.WinVelocity >= RankSettings.WinStreakThreshold):
                set FinalGain = RankSettings.BaseGain * RankSettings.WinStreakMultiplier

            NewWinStreak := OldW.CurrentWinStreak + 1
            NewMaxWinStreak := if (NewWinStreak > OldW.MaxWinStreak) then NewWinStreak else OldW.MaxWinStreak
            NewEloW := OldW.Elo + FinalGain

            set WStats.Current = player_persistable_stats:
                Wins := OldW.Wins + 1,
                WinVelocity := OldW.WinVelocity + 1,
                LossDamping := 0,
                Elo := NewEloW,
                Kills := OldW.Kills,
                Deaths := OldW.Deaths,
                Losses := OldW.Losses,
                Headshots := OldW.Headshots,
                Suicides := OldW.Suicides,
                CurrentKillStreak := OldW.CurrentKillStreak,
                MaxKillStreak := OldW.MaxKillStreak,
                CurrentWinStreak := NewWinStreak,
                MaxWinStreak := NewMaxWinStreak
            SavePlayerStats(Winner)

            NewRankW := ResolveRankFromElo(NewEloW)
            NewProgW := GetRankProgress(NewEloW)

            StartPctW := if (SP := Round[OldProgW(0) * 100.0]) then SP else 0
            EndPctW := if (EP := Round[NewProgW(0) * 100.0]) then EP else 0
            DidRankUpW := if (NewRankW.Tier > OldRankW.Tier) then true else false

            # Award +25 Cybercash on first-time rank tier advancement
            if (DidRankUpW?):
                EconomyManager.CheckAndAwardRankUpCybercash(Winner, NewRankW.Tier)

            PercentDeltaW := if (DidRankUpW?):
                (100 - StartPctW) + EndPctW
            else EndPctW - StartPctW

            TransitionW := match_rank_transition:
                PreviousRank := OldRankW
                NewRank := NewRankW
                PreviousProgressScalar := OldProgW(0)
                NewProgressScalar := NewProgW(0)
                PreviousProgressPercent := OldProgW(1)
                NewProgressPercent := NewProgW(1)
                EloDelta := FinalGain
                EloDeltaText := "+{PercentDeltaW}%"
                IsPositiveEloDelta := true
                DidRankUp := DidRankUpW
                DidRankDown := false

            if. set LastMatchTransitions[Winner] = TransitionW

        # Process Loser
        if (LStats := SessionStats[Loser]):
            OldL := LStats.Current
            OldRankL := ResolveRankFromElo(OldL.Elo)
            OldProgL := GetRankProgress(OldL.Elo)

            var FinalLoss : float = RankSettings.BaseLoss
            if (OldL.LossDamping >= RankSettings.LossDampingThreshold):
                set FinalLoss = RankSettings.BaseLoss * RankSettings.LossMitigationFactor

            NewEloL := if (OldL.Elo - FinalLoss >= 0.0) 
            then OldL.Elo - FinalLoss else 0.0

            set LStats.Current = player_persistable_stats:
                Losses := OldL.Losses + 1,
                LossDamping := OldL.LossDamping + 1,
                WinVelocity := 0,
                Elo := NewEloL,
                Kills := OldL.Kills,
                Deaths := OldL.Deaths,
                Wins := OldL.Wins,
                Headshots := OldL.Headshots,
                Suicides := OldL.Suicides,
                CurrentKillStreak := OldL.CurrentKillStreak,
                MaxKillStreak := OldL.MaxKillStreak,
                CurrentWinStreak := 0,
                MaxWinStreak := OldL.MaxWinStreak
            SavePlayerStats(Loser)

            NewRankL := ResolveRankFromElo(NewEloL)
            NewProgL := GetRankProgress(NewEloL)

            StartPctL := if (SP := Round[OldProgL(0) * 100.0]) then SP else 0
            EndPctL := if (EP := Round[NewProgL(0) * 100.0]) then EP else 0
            DidRankDownL := if (NewRankL.Tier < OldRankL.Tier) then true else false

            PercentDeltaL := if (DidRankDownL?):
                StartPctL + (100 - EndPctL)
            else StartPctL - EndPctL

            TransitionL := match_rank_transition:
                PreviousRank := OldRankL
                NewRank := NewRankL
                PreviousProgressScalar := OldProgL(0)
                NewProgressScalar := NewProgL(0)
                PreviousProgressPercent := OldProgL(1)
                NewProgressPercent := NewProgL(1)
                EloDelta := -FinalLoss
                EloDeltaText := "-{PercentDeltaL}%"
                IsPositiveEloDelta := false
                DidRankUp := false
                DidRankDown := DidRankDownL

            if. set LastMatchTransitions[Loser] = TransitionL

        MatchFinalizedEvent.Signal((Winner, Loser))

    GetLastMatchTransition<public>(Agent : agent)<transacts> : ?match_rank_transition =
        if (Transition := LastMatchTransitions[Agent]):
            return option { Transition }
        return false

    ClearLastMatchTransition<public>(Agent : agent) : void =
        var NewTransitions : [agent]match_rank_transition = map{}
        for (Key -> Val : LastMatchTransitions, Key <> Agent):
            if. set NewTransitions[Key] = Val
        set LastMatchTransitions = NewTransitions

    ResolveRankFromElo<public>(Elo : float)<transacts> : rank_resolution =
        var ResolvedTier : int = 0
        var ResolvedRankName : string = "Unranked"
        var ResolvedIconType : rank_icon_type = rank_icon_type.Unranked

        for (Index -> Rank : RankSettings.RankTiers):
            if (Elo >= Rank.MinimumElo):
                set ResolvedTier = Index
                set ResolvedRankName = Rank.RankName
                set ResolvedIconType = Rank.IconType

        return rank_resolution:
            Tier := ResolvedTier
            RankName := ResolvedRankName
            RankIcon := ResolveRankTexture(ResolvedIconType)

    ResolveRankTexture<public>(IconType : rank_icon_type)<transacts> : texture =
        case (IconType):
            rank_icon_type.Unranked => UI.Unranked
            rank_icon_type.Bronze1 => UI.Bronze_1
            rank_icon_type.Bronze2 => UI.Bronze_2
            rank_icon_type.Bronze3 => UI.Bronze_3
            rank_icon_type.Silver1 => UI.Silver_1
            rank_icon_type.Silver2 => UI.Silver_2
            rank_icon_type.Silver3 => UI.Silver_3
            rank_icon_type.Gold1 => UI.Gold_1
            rank_icon_type.Gold2 => UI.Gold_2
            rank_icon_type.Gold3 => UI.Gold_3
            rank_icon_type.Platinum1 => UI.Plat_1
            rank_icon_type.Platinum2 => UI.Plat_2
            rank_icon_type.Platinum3 => UI.Plat_3
            rank_icon_type.Diamond1 => UI.Diamond_1
            rank_icon_type.Diamond2 => UI.Diamond_2
            rank_icon_type.Diamond3 => UI.Diamond_3
            rank_icon_type.Elite => UI.Elite
            rank_icon_type.Champion => UI.Champion
            rank_icon_type.Unreal => UI.Unreal
            rank_icon_type.FragMaster => UI.Frag_Master