using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/UI }

# Converts a float value into a decimal formatted string with specified precision.
ToMultiplierString<public>(Value : float, DecimalPlaces : int) : string =
    Scale : float = Pow(10.0, DecimalPlaces * 1.0)
    if (ScaledInt := Floor[Value * Scale + 0.5]):
        IsNegative : logic = if (ScaledInt < 0) then true else false
        DigitsString : string = ToString(Abs(ScaledInt))

        var Padded : string = DigitsString
        var ZerosNeeded : int = (DecimalPlaces + 1) - DigitsString.Length
        loop:
            if (ZerosNeeded <= 0) then break
            set Padded = "0{Padded}"
            set ZerosNeeded -= 1

        if (DecimalPlaces > 0):
            SplitIndex : int = Padded.Length - DecimalPlaces
            if (IntegerPart := Padded.Slice[0, SplitIndex]):
                if (DecimalPart := Padded.Slice[SplitIndex, Padded.Length]):
                    Formatted : string = "{IntegerPart}.{DecimalPart}"
                    if (IsNegative?) then "-{Formatted}" else Formatted
                else ToString(Value)
            else ToString(Value)
        else if (IsNegative?) then "-{Padded}" else Padded
    else ToString(Value)

# Rounds a float value to a given decimal place.
FormatFloat<public>(Value : float, decimalplace : float) : float =
    factor := Pow(10.0, decimalplace)
    if (RoundedInt := Int[Value * factor]):
        return (RoundedInt * 1.0) / factor
    else return 0.0

# Convert a String to a localized message.
StringToMessage<localizes><public>(String : string) : message = "{String}"

# Convert an Agent to a localized message.
AgentNameMessage<localizes><public>(Agent : agent) : message = "{Agent}"

# Format time in seconds to M:SS or SS.
FormatTime<public>(TimeInSeconds : float) : string =
    var TotalSeconds : int = 0
    if (FloorResult := Floor[TimeInSeconds]):
        set TotalSeconds = FloorResult

    var Minutes : int = 0
    if (FloorResult := Floor[(TotalSeconds * 1.0) / 60.0]):
        set Minutes = FloorResult

    var Seconds : int = 0
    if (ModResult := Mod[TotalSeconds, 60]):
        set Seconds = ModResult

    SecStr := if (Seconds < 10) then "0{Seconds}" else "{Seconds}"
    if (TotalSeconds < 60) then return "{Seconds}"
    else return "{Minutes}:{SecStr}"

# Formats a long number into a human-readable string.
FormatNumber<public>(Value : int, Shorthand : logic) : string =
    if (Shorthand = true) then FormatNumberShorthand(Value) else FormatNumberWithCommas(Value)

# Formats an integer with comma separators, e.g. 1,234,567
FormatNumberWithCommas<public>(Value : int) : string =
    if (Value = 0):
        return "0"

    IsNegative : logic = if (Value < 0) then true else false
    NumStr := ToString(Abs(Value))
    Len := NumStr.Length

    var Result : string = ""
    for (I := 0..Len - 1):
        if (C := NumStr[I]):
            set Result = "{Result}{C}"
            DigitsRemaining := Len - I - 1
            if (DigitsRemaining > 0, Mod[DigitsRemaining, 3] = 0):
                set Result = "{Result},"

    if (IsNegative?) then "-{Result}" else Result

# Formats an integer into shorthand notation, e.g. 1.25M, 45.6K
FormatNumberShorthand<public>(Value : int) : string =
    IsNegative : logic = if (Value < 0) then true else false
    AbsValue := Abs(Value)

    var Suffix : string = ""
    var ScaledValue : float = AbsValue * 1.0
    if (AbsValue >= 1000000000000000000):
        set Suffix = "Q"
        set ScaledValue = (AbsValue * 1.0) / 1000000000000000000.0
    else if (AbsValue >= 1000000000000000):
        set Suffix = "q"
        set ScaledValue = (AbsValue * 1.0) / 1000000000000000.0
    else if (AbsValue >= 1000000000000):
        set Suffix = "T"
        set ScaledValue = (AbsValue * 1.0) / 1000000000000.0
    else if (AbsValue >= 1000000000):
        set Suffix = "B"
        set ScaledValue = (AbsValue * 1.0) / 1000000000.0
    else if (AbsValue >= 1000000):
        set Suffix = "M"
        set ScaledValue = (AbsValue * 1.0) / 1000000.0
    else if (AbsValue >= 1000):
        set Suffix = "K"
        set ScaledValue = (AbsValue * 1.0) / 1000.0

    Formatted := if (Suffix <> "") then FormatFloatTwoDecimals(ScaledValue) else ToString(AbsValue)
    if (IsNegative?) then "-{Formatted}{Suffix}" 
    else "{Formatted}{Suffix}"

# Rounds a float to 2 decimal places and returns it as a string.
FormatFloatTwoDecimals<public>(Value : float) : string =
    IsNegative : logic = if (Value < 0.0) then true else false
    AbsVal := Abs(Value)
    if (RoundedInt := Round[AbsVal * 100.0]):
        if (WholePart := Quotient[RoundedInt, 100], DecimalPart := Mod[RoundedInt, 100]):
            Formatted := if (DecimalPart < 10) then "{WholePart}.0{DecimalPart}" else "{WholePart}.{DecimalPart}"
            if (IsNegative?) then "-{Formatted}" else Formatted
        else ToString(Value)
    else ToString(Value)

event_subscription := class:
    CancelEvent : event() = event(){}
    Cancel<public>() : void = CancelEvent.Signal()

# Asynchronous loop holding until the event is signaled or canceled
AwaitForEvent(Event : event(t), Callback : type {_(:t):void}, Subscription : event_subscription where t : type)<suspends> : void =
    race:
        loop:
            Payload := Event.Await()
            Callback(Payload)
        Subscription.CancelEvent.Await()

# Unified generic extension method for subscribing to any custom Verse event(t) (including event())
(Event : event(t) where t : type).Subscribe<public>(Callback : type {_(:t):void}) : event_subscription =
    Subscription := event_subscription{}
    spawn { AwaitForEvent(Event, Callback, Subscription) }
    return Subscription