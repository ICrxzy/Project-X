using { /Verse.org/Simulation }
using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/UI }
using { /Verse.org/Assets }
using { /Verse.org/Simulation/Tags }

# Tag for identifying the world-space Combat Card entity
combat_card_tag := class(tag) {}

# Player state in session
game_player_state := enum { Lobby, Queued, Preparing, Battling }

# Lifecycle states for physical 1v1 arenas
map_status := enum { Inactive, Pending, Active }

# Win condition types for 1v1 duels
win_condition_type := enum { FirstTo, BestOf }

# Contract Categories
contract_category := enum { Daily, Weekly, Milestone }

# Contract Requirement Types
contract_requirement_type := enum:
    Frags
    Deaths
    SelfFrags
    Wins
    Losses
    MatchesPlayed
    FragStreak
    WinStreak
    RankTier
    UniqueOpponentFrags
    PlaytimeMinutes

# Customization Categories (5 Rows on Customization Page)
customization_type<public> := enum:
    Backpack
    KillEffect
    Emblem
    Backplate
    Title

# Cosmetic Rarity / Tiers with Baseline Pricing
customization_tier<public> := enum:
    Tier1
    Tier2
    Tier3
    Tier4

# Customization Item Definition (Cleaned without Description)
customization_item_def<public> := struct<concrete>:
    Id : string = ""
    Type : customization_type = customization_type.Backpack
    Tier : customization_tier = customization_tier.Tier1
    Name : string = ""
    BasePrice : int = 0
    Thumbnail : texture = UI.Unranked
    VfxIndex : int = 0
    TitleText : string = ""
    IsDefaultUnlocked : logic = false

# Single Slot in the 3-Slot Visible Window (No Description or IsValid)
carousel_slot_data<public> := struct<concrete>:
    ItemId : string = ""
    Name : string = ""
    Thumbnail : texture = UI.Unranked
    Tier : customization_tier = customization_tier.Tier1
    IsEquipped : logic = false
    IsLocked : logic = true

# UI Model for a 3-Slot Row Page
carousel_page_data<public> := struct<concrete>:
    Category : customization_type = customization_type.Backpack
    PageIndex : int = 0
    TotalPages : int = 1
    TotalUnlockedItems : int = 0
    Slot1 : carousel_slot_data = carousel_slot_data{}
    Slot2 : carousel_slot_data = carousel_slot_data{}
    Slot3 : carousel_slot_data = carousel_slot_data{}

# Unified Live Player Card Data Model (Used for Lobby Preview and Arena Match HUD)
player_card_data<public> := struct<concrete>:
    PlayerName : string = ""
    EmblemThumbnail : texture = UI.Unranked
    BackplateThumbnail : texture = UI.Unranked
    TitleText : string = ""
    RankName : string = "Unranked"
    RankIcon : texture = UI.Unranked
    ShowRank : logic = true
    IsValid : logic = true

# Persisted Player Customization State Sub-struct
player_persistable_customization<public> := struct<concrete><persistable>:
    UnlockedItemIds : []string = array{}
    EquippedBackpackId : string = ""
    EquippedKillEffectId : string = ""
    EquippedEmblemId : string = ""
    EquippedBackplateId : string = ""
    EquippedTitleId : string = ""
    ShowRankOnCard : logic = true

# Persisted Economy Data Sub-struct
player_persistable_economy<public> := struct<concrete><persistable>:
    CybercashBalance : int = 0
    LifetimeCybercashEarned : int = 0
    HighestRankTierAwarded : int = 0

# Shop Slot Model
shop_slot_item<public> := struct<concrete>:
    Def : customization_item_def = customization_item_def{}
    DiscountPercent : int = 0
    FinalPrice : int = 0
    IsPurchased : logic = false
    IsFeatured : logic = false

# Weekly Featured 5-Item Bundle Model (Prorated Pricing & Per-Slot Ownership Flags)
featured_bundle_data<public> := struct<concrete>:
    BundleName : string = "WEEKLY FEATURED BUNDLE"
    BackpackItem : customization_item_def = customization_item_def{}
    KillEffectItem : customization_item_def = customization_item_def{}
    EmblemItem : customization_item_def = customization_item_def{}
    BackplateItem : customization_item_def = customization_item_def{}
    TitleItem : customization_item_def = customization_item_def{}
    OriginalPrice : int = 0
    UnownedOriginalPrice : int = 0
    DiscountPercent : int = 0
    FinalPrice : int = 0
    Slot1Owned : logic = false
    Slot2Owned : logic = false
    Slot3Owned : logic = false
    Slot4Owned : logic = false
    Slot5Owned : logic = false
    IsPurchased : logic = false
    IsValid : logic = false

# Static Contract Definition
contract_definition := struct<concrete>:
    Id : string = ""
    Category : contract_category = contract_category.Daily
    Title : string = ""
    Description : string = ""
    RequirementType : contract_requirement_type = contract_requirement_type.Frags
    TargetValue : int = 0
    RequiredRankTier : int = 0
    RewardCosmeticId : string = ""

# UI-Facing Contract Data
contract_ui_data := struct<concrete>:
    Id : string = ""
    Category : contract_category = contract_category.Daily
    Title : string = ""
    Description : string = ""
    CurrentProgress : int = 0
    TargetProgress : int = 0
    ProgressScalar : float = 0.0
    ProgressPercent : string = ""
    IsCompleted : logic = false
    IsNewlyCompleted : logic = false
    RewardCosmeticId : string = ""

# Post-Match Contract Progression Summary for AAR
contract_match_summary := struct<concrete>:
    ContractId : string = ""
    Title : string = ""
    Category : contract_category = contract_category.Daily
    PreviousProgress : int = 0
    NewProgress : int = 0
    TargetProgress : int = 0
    ProgressDelta : int = 0
    IsCompleted : logic = false
    WasCompletedInMatch : logic = false
    RewardCosmeticId : string = ""

# Persisted individual rotating contract state
persisted_contract_entry := struct<concrete><persistable>:
    Id : string = ""
    BaselineValue : int = 0
    CustomEventProgress : int = 0
    IsCompleted : logic = false

# Persistent player contracts storage structure
player_persistable_contracts := struct<concrete><persistable>:
    DailyCycleId : int = 0
    ActiveDailyContracts : []persisted_contract_entry = array{}
    WeeklyCycleId : int = 0
    ActiveWeeklyContracts : []persisted_contract_entry = array{}
    CompletedMilestoneIds : []string = array{}
    UniqueVictimIds : []string = array{}
    TrackedPlaytimeSeconds : float = 0.0

match_rank_transition := struct:
    PreviousRank : rank_resolution
    NewRank : rank_resolution
    PreviousProgressScalar : float
    NewProgressScalar : float
    PreviousProgressPercent : string
    NewProgressPercent : string
    EloDelta : float
    EloDeltaText : string
    IsPositiveEloDelta : logic
    DidRankUp : logic
    DidRankDown : logic

# Session and persistent player preferences
player_preferences := struct<concrete>:
    AutoQueue : logic = true
    MusicEnabled : logic = true
    SoundFXEnabled : logic = true

rank_icon_type := enum:
    Unranked
    Bronze1
    Bronze2
    Bronze3
    Silver1
    Silver2
    Silver3
    Gold1
    Gold2
    Gold3
    Platinum1
    Platinum2
    Platinum3
    Diamond1
    Diamond2
    Diamond3
    Elite
    Champion
    Unreal
    FragMaster

rank_resolution<public> := struct:
    Tier : int
    RankName : string
    RankIcon : texture

# Match configuration settings for 1v1 duels
match_settings := struct<concrete>:
    @editable:
        ToolTip := WinConditionTypeInfo
    WinCondition : win_condition_type = win_condition_type.BestOf

    @editable:
        ToolTip := WinConditionScoreInfo
    WinConditionScore : int = 3

    @editable:
        ToolTip := RoundTimeLimitInfo
    RoundTimeLimit : float = 60.0

    @editable:
        ToolTip := OvertimeLengthInfo
    OvertimeLength : float = 10.0

    @editable:
        ToolTip := RoundStasisDurationInfo
    RoundStasisDuration : float = 5.0

    @editable:
        ToolTip := InterRoundDelayInfo
    InterRoundDelay : float = 2.0

    @editable:
        ToolTip := UseTiebreakerInfo
    UseTiebreaker : logic = false
    
    @editable ArenaCooldown : float = 12.0

    @editable:
        ToolTip := MaxDrawsInfo
    MaxDrawsBeforeCancel : int = 2

    @editable:
        ToolTip := SuicidePenaltyInfo
    SubtractScoreOnSuicide : logic = false

# Persistent player statistics structure
player_persistable_stats := struct<concrete><persistable>:
    Kills : int = 0
    Deaths : int = 0
    Wins : int = 0
    Losses : int = 0
    Headshots : int = 0
    Suicides : int = 0
    Elo : float = 1000.0
    WinVelocity : int = 0
    LossDamping : int = 0
    CurrentKillStreak : int = 0
    MaxKillStreak : int = 0
    CurrentWinStreak : int = 0
    MaxWinStreak : int = 0

# Runtime session stats wrapper
player_stats := class<unique>():
    Player : agent
    var Current : player_persistable_stats = player_persistable_stats{}
    var JoinTime : float = 0.0

# Blitz loadout granters (Primary, Special, Utility)
blitz_loadout_data := struct<concrete>:
    @editable:
        ToolTip := PrimaryGranterInfo
    PrimaryGranter : item_granter_device = item_granter_device{}

    @editable:
        ToolTip := SpecialGranterInfo
    SpecialGranter : item_granter_device = item_granter_device{}

    @editable:
        ToolTip := UtilityGranterInfo
    UtilityGranter : item_granter_device = item_granter_device{}
        
# Arena general identification
arena_map_general := struct<concrete>:
    @editable:
        ToolTip := MapNameInfo
    MapName : string = "Arena Name"

    @editable:
        ToolTip := MapThumbnailInfo
    LargeThumbnail : texture = UI.Unranked

    @editable:
        ToolTip := MapThumbnailInfo
    SmallThumbnail : texture = UI.Unranked

# Arena logic and controller devices
arena_map_logic := struct<concrete>:
    @editable:
        ToolTip := ResetExplosiveInfo
    ResetExplosive : explosive_device = explosive_device{}

    @editable:
        ToolTip := ControllerInfo
    Controller : arena_controller = arena_controller{}

# Arena gameplay resource devices
arena_map_gameplay := struct<concrete>:
    @editable:
        ToolTip := HealthPowerupInfo
    HealthPowerups : []health_powerup_device = array{}

    @editable:
        ToolTip := DamagePowerupInfo
    DamagePowerups : []damage_amplifier_powerup_device = array{}

    @editable:
        ToolTip := GrindPowerupInfo
    GrindPowerups : []grind_powerup_device = array{}

    @editable:
        ToolTip := StatPowerupInfo
    StatPowerups : []stat_powerup_device = array{}

    @editable:
        ToolTip := VfxPowerupInfo
    VfxPowerups : []visual_effect_powerup_device = array{}

    @editable:
        ToolTip := ItemSpawnerInfo
    WeaponSpawners : []item_spawner_device = array{}

# Dedicated 1v1 arena definition
arena_map := class<unique><concrete>():
    @editable:
        ToolTip := ArenaGeneralInfo
    General : arena_map_general = arena_map_general{}

    @editable:
        ToolTip := LoadoutIndexInfo
    LoadoutIndex : int = 0

    @editable:
        ToolTip := ArenaLogicInfo
    LogicDevices : arena_map_logic = arena_map_logic{}

    @editable:
        ToolTip := Player1SpawnInfo
    Player1Spawn : teleporter_device = teleporter_device{}

    @editable:
        ToolTip := Player2SpawnInfo
    Player2Spawn : teleporter_device = teleporter_device{}

    @editable:
        ToolTip := ArenaGameplayInfo
    Gameplay : arena_map_gameplay = arena_map_gameplay{}

    var Status : map_status = map_status.Inactive
    var CooldownGeneration : int = 0

# ==============================================================================
# UNIFIED MASTER PLAYER PROFILE PERSISTENCE
# Exactly 1 module-scoped persistent var for the entire project
# ==============================================================================
player_profile<public> := class<final><persistable>:
    Stats<public> : player_persistable_stats = player_persistable_stats{}
    Contracts<public> : player_persistable_contracts = player_persistable_contracts{}
    Customization<public> : player_persistable_customization = player_persistable_customization{}
    Economy<public> : player_persistable_economy = player_persistable_economy{}

# Single global persistent storage weak_map
var MasterProfileStorage<public> : weak_map(player, player_profile) = map{}

GetPlayerProfile<public>(Plr : player) : player_profile =
    if (Profile := MasterProfileStorage[Plr]) then Profile else player_profile{}

SavePlayerStatsToProfile<public>(Plr : player, NewStats : player_persistable_stats) : void =
    Profile := GetPlayerProfile(Plr)
    Updated := player_profile:
        Stats := NewStats
        Contracts := Profile.Contracts
        Customization := Profile.Customization
        Economy := Profile.Economy
    if. set MasterProfileStorage[Plr] = Updated

SavePlayerContractsToProfile<public>(Plr : player, NewContracts : player_persistable_contracts) : void =
    Profile := GetPlayerProfile(Plr)
    Updated := player_profile:
        Stats := Profile.Stats
        Contracts := NewContracts
        Customization := Profile.Customization
        Economy := Profile.Economy
    if. set MasterProfileStorage[Plr] = Updated

SavePlayerCustomizationToProfile<public>(Plr : player, NewCustomization : player_persistable_customization) : void =
    Profile := GetPlayerProfile(Plr)
    Updated := player_profile:
        Stats := Profile.Stats
        Contracts := Profile.Contracts
        Customization := NewCustomization
        Economy := Profile.Economy
    if. set MasterProfileStorage[Plr] = Updated

SavePlayerEconomyToProfile<public>(Plr : player, NewEconomy : player_persistable_economy) : void =
    Profile := GetPlayerProfile(Plr)
    Updated := player_profile:
        Stats := Profile.Stats
        Contracts := Profile.Contracts
        Customization := Profile.Customization
        Economy := NewEconomy
    if. set MasterProfileStorage[Plr] = Updated