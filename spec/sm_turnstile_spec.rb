require File.dirname(__FILE__) + '/spec_helper'

context "Turn Stile" do
  include TurnstileStatemachine
  
  setup do
    create_turnstile
  end
  
  specify "connections" do
    locked_state = @sm.get_state(:locked)
    unlocked_state = @sm.get_state(:unlocked)
    
    locked_state.transitions.length.should_be 2
    unlocked_state.transitions.length.should_be 2
    
    check_transition(locked_state.transitions[:coin], :locked, :unlocked, :coin, @unlock)
    check_transition(locked_state.transitions[:pass], :locked, :locked, :pass, @alarm)
    check_transition(unlocked_state.transitions[:pass], :unlocked, :locked, :pass, @lock)
    check_transition(unlocked_state.transitions[:coin], :unlocked, :locked, :coin, @thankyou)
  end
  
  specify "start state" do
    @sm.reset
    @sm.startstate.should.be :locked
    @sm.state.should.be :locked
  end
  
  specify "bad event" do
    begin
      @sm.process_event(:blah)
      self.should.fail_with_message("Exception expected")
    rescue Exception => e
      e.class.should.be Statemachine::StatemachineException
      e.to_s.should_eql "'locked' state does not respond to the 'blah' event."
    end
  end
  
  specify "locked state with a coin" do
    @sm.process_event(:coin)
    
    @sm.state.should.be :unlocked
    @locked.should.be false
  end
  
  specify "locked state with pass event" do
    @sm.process_event(:pass)
    
    @sm.state.should.be :locked
    @locked.should.be true
    @alarm_status.should.be true
  end

  specify "unlocked state with coin" do
    @sm.process_event(:coin)
    @sm.process_event(:coin)
    
    @sm.state.should.be :locked
    @thankyou_status.should.be true
  end

  specify "unlocked state with pass event" do
    @sm.process_event(:coin)
    @sm.process_event(:pass)
    
    @sm.state.should.be :locked
    @locked.should.be true
  end

  specify "events invoked via method_missing" do
    @sm.coin
    @sm.state.should.be :unlocked
    @sm.pass
    @sm.state.should.be :locked
  end
end
