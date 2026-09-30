using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Verse }
using { /UnrealEngine.com/Marketplace }
using { /Verse.org/Assets }
# Top-level localized strings for Commerce Entitlements and Offers
EntitlementTier1Name<localizes> : message = "Cybercash 500 Pack"
EntitlementTier1Desc<localizes> : message = "Grants 500 Cybercash for the in-game cosmetic shop."
EntitlementTier1Short<localizes> : message = "500 Cybercash"

EntitlementTier2Name<localizes> : message = "Cybercash 1,300 Pack"
EntitlementTier2Desc<localizes> : message = "Grants 1,300 Cybercash for the in-game cosmetic shop."
EntitlementTier2Short<localizes> : message = "1,300 Cybercash"

EntitlementTier3Name<localizes> : message = "Cybercash 2,800 Pack"
EntitlementTier3Desc<localizes> : message = "Grants 2,800 Cybercash for the in-game cosmetic shop."
EntitlementTier3Short<localizes> : message = "2,800 Cybercash"

EntitlementTier4Name<localizes> : message = "Cybercash 7,000 Apex Pack"
EntitlementTier4Desc<localizes> : message = "Grants 7,000 Cybercash for the in-game cosmetic shop."
EntitlementTier4Short<localizes> : message = "7,000 Cybercash"

# Marketplace Entitlement Definitions (Implementing has_icon and has_description)
cybercash_entitlement_tier1<public> := class<concrete>(entitlement):
    var Icon<override> : texture = UI.Unranked
    var Name<override> : message = EntitlementTier1Name
    var Description<override> : message = EntitlementTier1Desc
    var ShortDescription<override> : message = EntitlementTier1Short
    MaxCount<override> : int = 99999
    Consumable<override> : logic = true

cybercash_entitlement_tier2<public> := class<concrete>(entitlement):
    var Icon<override> : texture = UI.Unranked
    var Name<override> : message = EntitlementTier2Name
    var Description<override> : message = EntitlementTier2Desc
    var ShortDescription<override> : message = EntitlementTier2Short
    MaxCount<override> : int = 99999
    Consumable<override> : logic = true

cybercash_entitlement_tier3<public> := class<concrete>(entitlement):
    var Icon<override> : texture = UI.Unranked
    var Name<override> : message = EntitlementTier3Name
    var Description<override> : message = EntitlementTier3Desc
    var ShortDescription<override> : message = EntitlementTier3Short
    MaxCount<override> : int = 99999
    Consumable<override> : logic = true

cybercash_entitlement_tier4<public> := class<concrete>(entitlement):
    var Icon<override> : texture = UI.Unranked
    var Name<override> : message = EntitlementTier4Name
    var Description<override> : message = EntitlementTier4Desc
    var ShortDescription<override> : message = EntitlementTier4Short
    MaxCount<override> : int = 99999
    Consumable<override> : logic = true

economy_manager := class(creative_device):
    # Marketplace Entitlement Offers (Fully initialized archetypes, Max tier <= $20 USD / 2,200 V-Bucks)
    var OfferTier1 : entitlement_offer = entitlement_offer{
        EntitlementType := cybercash_entitlement_tier1,
        Price := MakePriceVBucks(200.0),
        Icon := UI.Unranked,
        Name := EntitlementTier1Name,
        Description := EntitlementTier1Desc,
        ShortDescription := EntitlementTier1Short
    }
    var OfferTier2 : entitlement_offer = entitlement_offer{
        EntitlementType := cybercash_entitlement_tier2,
        Price := MakePriceVBucks(500.0),
        Icon := UI.Unranked,
        Name := EntitlementTier2Name,
        Description := EntitlementTier2Desc,
        ShortDescription := EntitlementTier2Short
    }
    var OfferTier3 : entitlement_offer = entitlement_offer{
        EntitlementType := cybercash_entitlement_tier3,
        Price := MakePriceVBucks(1000.0),
        Icon := UI.Unranked,
        Name := EntitlementTier3Name,
        Description := EntitlementTier3Desc,
        ShortDescription := EntitlementTier3Short
    }
    var OfferTier4 : entitlement_offer = entitlement_offer{
        EntitlementType := cybercash_entitlement_tier4,
        Price := MakePriceVBucks(2200.0),
        Icon := UI.Unranked,
        Name := EntitlementTier4Name,
        Description := EntitlementTier4Desc,
        ShortDescription := EntitlementTier4Short
    }

    # Runtime Cache
    var PlayerEconomyMap : [agent]player_persistable_economy = map{}

    # Event signaling balance updates (Agent, NewBalance, Delta)
    CybercashUpdatedEvent<public> : event(tuple(agent, int, int)) = event(tuple(agent, int, int)){}

    OnBegin<override>()<suspends> : void =
        GetPlayspace().PlayerAddedEvent().Subscribe(InitializePlayerEconomy)
        GetPlayspace().PlayerRemovedEvent().Subscribe(OnPlayerRemoved)
        for (P : GetPlayspace().GetPlayers()) do InitializePlayerEconomy(P)

    InitializePlayerEconomy<public>(Agent : agent) : void =
        if (Plr := player[Agent]):
            Profile := GetPlayerProfile(Plr)
            if. set PlayerEconomyMap[Agent] = Profile.Economy

    OnPlayerRemoved(P : player) : void =
        SavePlayerEconomy(P)
        var NewEconomyMap : [agent]player_persistable_economy = map{}
        for (Key -> Val : PlayerEconomyMap, Key <> P):
            if. set NewEconomyMap[Key] = Val
        set PlayerEconomyMap = NewEconomyMap

    SavePlayerEconomy(Plr : player) : void =
        if (Data := PlayerEconomyMap[Plr]):
            SavePlayerEconomyToProfile(Plr, Data)

    GetCybercashBalance<public>(Agent : agent)<transacts> : int =
        if (Data := PlayerEconomyMap[Agent]):
            return Data.CybercashBalance
        return 0

    CreditCybercash<public>(Agent : agent, Amount : int) : void =
        if (Amount <= 0) then return
        if (Plr := player[Agent], Data := PlayerEconomyMap[Agent]):
            NewBalance := Data.CybercashBalance + Amount
            NewLifetime := Data.LifetimeCybercashEarned + Amount
            Updated := player_persistable_economy:
                CybercashBalance := NewBalance
                LifetimeCybercashEarned := NewLifetime
                HighestRankTierAwarded := Data.HighestRankTierAwarded
            if. set PlayerEconomyMap[Agent] = Updated
            SavePlayerEconomy(Plr)
            CybercashUpdatedEvent.Signal((Agent, NewBalance, Amount))
            Print("[EconomyManager] Credited +{Amount} Cybercash to player. Balance: {NewBalance}.")

    DebitCybercash<public>(Agent : agent, Amount : int) : logic =
        if (Amount <= 0) then return true
        if (Plr := player[Agent], Data := PlayerEconomyMap[Agent]):
            if (Data.CybercashBalance >= Amount):
                NewBalance := Data.CybercashBalance - Amount
                Updated := player_persistable_economy:
                    CybercashBalance := NewBalance
                    LifetimeCybercashEarned := Data.LifetimeCybercashEarned
                    HighestRankTierAwarded := Data.HighestRankTierAwarded
                if. set PlayerEconomyMap[Agent] = Updated
                SavePlayerEconomy(Plr)
                CybercashUpdatedEvent.Signal((Agent, NewBalance, -Amount))
                Print("[EconomyManager] Debited -{Amount} Cybercash from player. Balance: {NewBalance}.")
                return true
        return false

    # --- Strict Freemium Reward Sources ---

    # 1. Daily Quest: +25 Cybercash
    AwardDailyQuestCybercash<public>(Agent : agent) : void =
        CreditCybercash(Agent, 25)

    # 2. Weekly Quest: +50 Cybercash
    AwardWeeklyQuestCybercash<public>(Agent : agent) : void =
        CreditCybercash(Agent, 50)

    # 3. Milestone Quests: +10 to +50 Cybercash scaled by threshold
    AwardMilestoneCybercash<public>(Agent : agent, TargetValue : int) : void =
        RewardAmount := if (TargetValue >= 500) then 50 else if (TargetValue >= 100) then 25 else 10
        CreditCybercash(Agent, RewardAmount)

    # 4. First-Time Rank Up: +25 Cybercash (Never repeats on rank drops)
    CheckAndAwardRankUpCybercash<public>(Agent : agent, NewTier : int) : void =
        if (Plr := player[Agent], Data := PlayerEconomyMap[Agent]):
            if (NewTier > Data.HighestRankTierAwarded):
                NewBalance := Data.CybercashBalance + 25
                NewLifetime := Data.LifetimeCybercashEarned + 25
                Updated := player_persistable_economy:
                    CybercashBalance := NewBalance
                    LifetimeCybercashEarned := NewLifetime
                    HighestRankTierAwarded := NewTier
                if. set PlayerEconomyMap[Agent] = Updated
                SavePlayerEconomy(Plr)
                CybercashUpdatedEvent.Signal((Agent, NewBalance, 25))
                Print("[EconomyManager] First-time Rank Up to Tier {NewTier}! Awarded +25 Cybercash.")

    # --- Marketplace Purchases ---
    PurchaseVBucksPack<public>(Agent : agent, PackTier : int)<suspends> : logic =
        if (Plr := player[Agent]):
            SelectedOffer := case (PackTier):
                1 => OfferTier1
                2 => OfferTier2
                3 => OfferTier3
                _ => OfferTier4

            GrantAmount := case (PackTier):
                1 => 500
                2 => 1300
                3 => 2800
                _ => 7000

            BuyResult := BuyOffer(Plr, SelectedOffer)
            if (BuyResult = true):
                CreditCybercash(Agent, GrantAmount)
                return true
        return false