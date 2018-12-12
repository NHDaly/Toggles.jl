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

Base.@pure __make_ctx(::Type{T}) where {T} = ToggleCtx(metadata=Val(T))

Cassette.execute(::ToggleCtx{Val{TriggerType}}, thunk::ToggleThunk{TriggerType}) where {TriggerType} = thunk.r()
toggle(trigger::TriggerType, f::F, args...; kwargs...) where {TriggerType,F} = Cassette.overdub(__make_ctx(TriggerType), (args...) -> f(args...; kwargs...), args...)
#toggle(trigger::TriggerType, f::F, args...) where {TriggerType,F} = Cassette.overdub(__make_ctx(TriggerType), f, args...)

macro toggle(trigger, expr)
    return :(toggle($(esc(trigger)), ()->$(esc(expr))))
end

end
