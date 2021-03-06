package states;
import actors.Actor;
import events.StateChangeEvent;
import events.AnimateEvent;
import world.Node;
import systems.AStar;
import tween.Delta;
import events.MoveEvent;
import events.SimpleEvents;
import sdg.event.EventObject;

class MoveState extends MovingState
{
	private var lastTargetNode:Node;
	private var turnsIdle:Int = 0;

	public function new(a:Actor)
	{
		super(a);
		
		if(a.data['mobile'])
			a.eventDispatcher.addEvent(MoveEvent.MOVE, MoveToNode);
		else
			trace('mobile unit created without mobile flag');
		a.eventDispatcher.addEvent(SimpleEvents.STOP, resetData);
	}

	public override function enter()
	{
		super.enter();
		actor.coolDown = Std.int(actor.data['moveCoolDown']);
	}

	/**
	 * moves to the next node. If a path doesn't exist to the targetNode, it creates one
	 * It then attepts to move. if blocked a new path will be found
	 */
	public override function takeAction():Void
	{
		super.takeAction();

		if (actor.data['aggressive'])
		{
			checkView();
			actor.data['targetEnemy'] = getEnemyInThreat();	
			if(actor.data['targetEnemy'] != null)
			{
				actor.eventDispatcher.dispatchEvent(StateChangeEvent.CHANGE, new StateChangeEvent('attacking'));
				return;
			}
		}
		
		if ((actor.data['targetNode'] != null && path.length == 0|| actor.data['targetNode'] != lastTargetNode) && actor.data['targetNode'].isPassible())
		{
			path = AStar.newPath(actor.currentNodes[0], actor.data['targetNode']);//remember path[0] is the last 
		}
		
		if (path.length > 1 && path[1].occupant == null)
		{
			moveAlongPath();
			turnsIdle = 0;
			if (actor.currentNodes[0] == actor.data['targetNode'])
			{
				path = [];
				actor.data['targetNode'] = null;
				actor.eventDispatcher.dispatchEvent(StateChangeEvent.CHANGE, new StateChangeEvent('idle'));//Unlike other cases, this is after the action has been carried out.
			}
		}
		else if (path.length > 1 && path[1].occupant != null)
		{
			newPath();
		}
		else
		{
			turnsIdle++;
			if(turnsIdle > 3)
			{
				actor.data['targetNode'] = null;
				actor.eventDispatcher.dispatchEvent(StateChangeEvent.CHANGE, new StateChangeEvent('idle'));
			}
		}
		lastTargetNode = actor.data['targetNode'];
		
		animateMove();
	}

	/**
	 * sets node to move to with move sequence, if the event says aggressive, it attacks enemies on the way
	 * if aggressive is off, it will ignore all enemies
	 * @param	moveEvent
	 */
	public function MoveToNode(moveEvent:MoveEvent)
	{
		actor.eventDispatcher.dispatchEvent(SimpleEvents.STOP, new EventObject());
		actor.data['targetNode'] = moveEvent.node;
		actor.data['aggressive'] = moveEvent.aggressive;
		actor.eventDispatcher.dispatchEvent(StateChangeEvent.CHANGE, new StateChangeEvent('moving'));
	}
	
	/**
	 * resets all the decision making vars to null or false
	 * 
	 * @param	eO		EventObject is required for listenerCallbacks
	 */
	public function resetData(eO:EventObject = null):Void 
	{
		actor.data.set('targetNode', null);
		actor.data.set('aggressive', false);
	}
}