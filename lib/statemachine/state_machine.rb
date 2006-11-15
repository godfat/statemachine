module Statemachine
  
  class StatemachineException < Exception
  end
  
  class Statemachine
    
    include ActionInvokation
  
    attr_accessor :tracer, :context
    attr_reader :root
  
    def initialize(root = Superstate.new(:root, nil, self))
      @root = root
      @states = {}
    end
    
    def startstate
      return @root.startstate_id
    end
  
    def reset
      @state = get_state(@root.startstate_id)
      while @state and not @state.is_concrete?
        @state = get_state(@state.startstate_id)
      end
      raise StatemachineException.new("The state machine doesn't know where to start. Try setting the startstate.") if @state == nil
    end
    
    def state
      return @state.id
    end
    
    def state= value
      if value.is_a? State
        @state = value
      elsif @states[value]
        @state = @states[value]
      elsif value and @states[value.to_sym]
        @state = @states[value.to_sym]
      end
    end
    
    def process_event(event, *args)
      event = event.to_sym
      trace "Event: #{event}"
      if @state
        transition = @state.transitions[event]
        if transition
          transition.invoke(@state, self, args)
        else
          raise StatemachineException.new("#{@state} does not respond to the '#{event}' event.")
        end
      else
        raise StatemachineException.new("The state machine isn't in any state while processing the '#{event}' event.")
      end
    end
    
    def trace(message)
      @tracer.puts message if @tracer
    end
    
    def get_state(id)
      if @states.has_key? id
        return @states[id]
      elsif(is_history_state_id?(id))
        superstate_id = base_id(id)
        superstate = @states[superstate_id]
        raise StatemachineException.new("No history exists for #{superstate} since it is not a super state.") if superstate.is_concrete?
        raise StatemachineException.new("#{superstate} doesn't have any history yet.") if not superstate.history
        return superstate.history
      else
        state = State.new(id, @root, self)
        @states[id] = state
        return state
      end
    end
    
    def add_state(state)
      @states[state.id] = state
    end
    
    def has_state(id)
      if(is_history_state_id?(id))
        return @states.has_key?(base_id(id))
      else
        return @states.has_key?(id)
      end
    end
    
    def method_missing(message, *args)
      if @state and @state.transitions[message]
        method = self.method(:process_event)
        params = [message.to_sym].concat(args)
        method.call(*params)
      else
        super(message, args)
      end
    end
    
    private 
    
    def is_history_state_id?(id)
      return id.to_s[-2..-1] == "_H"
    end
    
    def base_id(history_id)
      return history_id.to_s[0...-2].to_sym
    end
    
  end

end