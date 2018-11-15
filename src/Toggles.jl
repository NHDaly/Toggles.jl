module Toggles

using Cassette

struct DefaultToggleTrigger end

macro toggleable(expr, trigger = DefaultToggleTrigger(), replacement = nothing)
    :(Toggles.ToggleThunk{typeof($(esc(trigger)))}(() -> $(esc(expr)), () -> $(esc(replacement)))())
end

# This struct acts as a hook to help Cassette find our code to replace.
struct ToggleThunk{Trigger, F<:Function, ReplacementType<:Function}
    f::F
    r::ReplacementType
    ToggleThunk{Trigger}(f::F, r::R) where {Trigger,F,R} = new{Trigger,F,R}(f,r)
end

@noinline (thunk::ToggleThunk)() = thunk.f()

Cassette.@context ToggleCtx

Cassette.execute(::ToggleCtx{TriggerType}, thunk::ToggleThunk{TriggerType}) where {TriggerType} = thunk.r()
toggle(trigger::TriggerType, f, args...; kwargs...) where {TriggerType} = Cassette.@overdub(ToggleCtx(metadata=trigger), f(args...; kwargs...))

macro toggle(trigger, expr)
    return :(toggle($(esc(trigger)), ()->$(esc(expr))))
end

end
