package components;

import actors.Actor;
import states.IState;
import events.TargetEvent;
import events.MoveEvent;
import events.StopEvent;
import events.StateChangeEvent;
import sdg.event.EventObject;
import components.ActorComponent;
import states.StateFactory;
import systems.Data;
import haxe.Timer;

class StateAI extends ActorComponent implements AI
{
	var states:Map<String, IState> = new Map<String, IState>();
	var state:IState;
	var nextState:String;
	var currentState:String;
	var lastState:String = null;
	/**
	 * timer whose frequency is set by speed
	 */
	private var actionTimer:Timer;

	/**
	 * offset delay timer that starts the action timer. Used to keep AI from starting at the same time. Set to 0 - 1 sec
	 */
	private var delayTimer:Timer;

	public function new ()
	{
		super();
	}
	public override function init()
	{
		super.init();

		object.eventDispatcher.addEvent(StopEvent.STOP, resetStates);
		object.eventDispatcher.addEvent(StateChangeEvent.CHANGE, changeState);

		var ais:Array<Dynamic> = cast (Data.dataMap['ai'][actor.data['ai']]['states'], Array<Dynamic>);
		for(i in ais)
		{
			var key:String = 'idle';
			if(i.name.indexOf('main') == -1)
				key = i.name;
			states.set(key, StateFactory.create(i.name, actor));
		}
		
		state = states.get('idle');
		//Keeps mass created units from updating at the exact same time. 
		//Idea from: http://answers.unity3d.com/questions/419786/a-pathfinding-multiple-enemies-MOVING-target-effic.html
		delayTimer = new Timer(Math.floor(300*Math.random()));
		delayTimer.run = delayedStart;
	}
	/**
	* end of delay timer that starts the takeAction cycle. 
	* This prevents too many AI scripts firing at once
	*/
	private function delayedStart()
    {
	   delayTimer.stop();
	   actionTimer = new Timer(actor.data['speed']);
	   actionTimer.run = takeAction;
    }
	/**
	 * drives actions based on state
	 */
	public function takeAction() 
	{
		if(nextState != null)
		{
			currentState = nextState;
			state = states[currentState];
			nextState = null;
		}
		lastState = currentState;
		state.takeAction();
	}
	
	/**
	 * resets state to idle
	 * 
	 * @param	eO		EventObject is required for listenerCallbacks
	 */
	public function resetStates(eO:StopEvent = null):Void 
	{
		nextState = 'idle';
	}

	private function changeState(e:StateChangeEvent)
	{
		if(states.exists(e.state))
		{
			if(e.immediate)
			{
				currentState = e.state;
				states[currentState].takeAction();
			}
			else
			{
				nextState = e.state;
			}
		}
	}
	/**
	 * detatches component and stops the UnitAI's action Timer
	 */
	public override function destroy() 
	{
		if (actionTimer != null)
		{
			actionTimer.stop();
		}
		super.destroy();
		object.components.remove(this);
	}
}