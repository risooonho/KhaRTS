package actors;

import world.Node;
import systems.Team;
import events.BuildAtEvent;
import events.TargetEvent;
import events.GatherEvent;
import events.MoveEvent;

class ActorList
{
	public var list:Array<Actor>;
	/**
	 * Team Actor belongs to
	 */
	public var team:Team = null;
	public function new() 
	{
		list = [];
	}

	public function iterator()
	{
		return list.iterator();
	}

	public function target(a:Actor)
	{
		for(actor in list)
		{
			actor.eventDispatcher.dispatchEvent(TargetEvent.ATTACK_ACTOR, new TargetEvent(a));
		}
	}

	public function gather(a:Actor)
	{
		for(actor in list)
		{
			var gathering:Bool = false;
			var resources:Array<Dynamic> = actor.data['resources'];
			for(i in resources)
			{
				if(i.name == a.data['resource'])
				{
					actor.eventDispatcher.dispatchEvent(GatherEvent.GATHER, new GatherEvent(a));
					gathering = true;
					break;
				}
			}
			if(!gathering)
				actor.eventDispatcher.dispatchEvent(MoveEvent.MOVE, new MoveEvent(a.currentNodes[0], false));
		}
	}
	/**
	* does two passes, one without double booking a unit, the next replacing what ever they were working on
	*/
	public function build(a:Actor)
	{
		for(i in 0...2)
		{
			for(actor in list)
			{
				if(actor.data.exists('buildings'))
				{
					var buildingsToBuild:Array<String> = [];
					var bObjects:Array<Dynamic> = actor.data['buildings'];
					for(i in bObjects)
					{
						buildingsToBuild.push(i.name);
					}
					//on second pass it doesn't matter if it was working on something else
					if(buildingsToBuild.indexOf(a.data['name']) != -1 && (actor.data['targetBuilding'] == null || i == 1))
					{
						//actor.eventDispatcher.dispatchEvent(SetBuildingEvent.BUILD_ACTOR, new SetBuildingEvent(a));
						actor.eventDispatcher.dispatchEvent(BuildAtEvent.BUILD, new BuildAtEvent(a.currentNodes[0], a.data));
						return;
					}
				}
			}
		}
	}

	public function moveTo(node:Node, aggressive:Bool = false)
	{
		var nodes:Array<Node> = [node];
		var lastLength:Int = 1;
		var i:Int = 0;
		while(nodes.length < list.length)
		{
			lastLength = nodes.length;
			for(k in nodes[i].neighbors)
			{
				if(nodes.indexOf(k) == -1 && k.isPassible())
				{
					nodes.push(k);
				}
			}
			i++;
		}

		i = 0;
		for(actor in list)
		{
			actor.eventDispatcher.dispatchEvent(MoveEvent.MOVE, new MoveEvent(nodes[i], aggressive));
			i++;
			if(i == nodes.length)
				break;
		}
	}

	public inline function push(a:Actor):Int
	{
		team = a.team;
		return list.push(a);
	}

	public inline function indexOf(a:Actor):Int
	{
		return list.indexOf(a);
	}

	public inline function concat( a : Array<Actor> ) : Array<Actor>
	{
		return list.concat(a);
	}

	public inline function pop() : Null<Actor>
	{
		return list.pop();
	}

	public inline function reverse() : Void
	{
		list.reverse();
	}

	public inline function shift() : Null<Actor>
	{
		return list.shift();
	}

	public inline function slice( pos : Int, ?end : Int ) : Array<Actor>
	{
		return list.slice(pos,end);
	}

	public inline function sort( f : Actor -> Actor -> Int ) : Void
	{
		list.sort(f);
	}

	public inline function splice( pos : Int, len : Int ) : Array<Actor>
	{
		return splice(pos,len);
	}

	public inline function toString() : String
	{
		return list.toString();
	}

	public inline function unshift( a : Actor ) : Void
	{
		list.unshift(a);
	}

	inline function insert( pos : Int, a : Actor ) : Void 
	{
		list.insert(pos,a);
	}

	inline function remove( a : Actor ) : Bool 
	{
		return list.remove(a);
	}

	public function purgeBuildings()
	{
		var bldings:Array<Actor> = [];
		for(i in list)
		{
			if(i.data['mobile'] == null)
			{
				bldings.push(i);
			}
		}
		if(bldings.length != list.length)
		{
			for(i in list)
			{
				if(i.data['mobile'] == null)
				{
					list.splice(list.indexOf(i),1);
				}
			}
		}
	}
}