package systems;

import sdg.Object;
import sdg.graphics.Sprite;
import sdg.atlas.Region;
import kha.Assets;
import sdg.atlas.Atlas;
import sdg.Sdg;
import sdg.ObjectList;
import actors.Actor;
import systems.UIElement;
import events.KillEvent;
import systems.ActorRepresentative;
import events.CenterOnUnitEvent;
import events.InputEvent;
import events.QueueEvent;
import world.Node;
import events.SetBuildingEvent;
import events.SelectBuildLocationEvent;

class UI extends SimpleEventDispatcher
{
	public var uiElements:ObjectList;
	public var buildingToBeBuilt:Object;
	/**
	 * map of Function arrays, and the Event Constant Strings used to trigger them
	 */
	private var dashboard:Object;
	private var units:Array<ActorRepresentative> = [];
	private var focusUnit:ActorRepresentative;
	private var controls:Array<UIElement> = [];
	private inline static var buttonWidth:Int = 16;

	public function new()
	{
		super();
		uiElements = new ObjectList(0,0);
		dashboard = new Dashboard(0,184, new Sprite(Assets.images.dashui));
		uiElements.add(dashboard);
		uiElements.apply(Sdg.screen.add);

		addEvent(KillEvent.KILL, killUnit);
		addEvent(CenterOnUnitEvent.CENTER, centerOnActor);
		addEvent(SelectBuildLocationEvent.SELECT, setBuildingToBuild);
	}

	public function setUnits(actors:Array<Actor>)
	{
		var dataArray:Array<Dynamic> = [];
		var d:Map<String, Dynamic>;
		var s:Sprite;
		var scaleDelta:Float;
		for(i in units)
		{
			uiElements.remove(i);
			Sdg.screen.remove(i,true);
		}
		for(i in controls)
		{
			uiElements.remove(i);
			Sdg.screen.remove(i,true);
		}
		if(focusUnit != null)
		{
			uiElements.remove(focusUnit);
			Sdg.screen.remove(focusUnit, true);
		}
		units = [];
		controls = [];
		focusUnit = null;
		var isUnits = false;
		var buttonNames:Array<String> = [];
		for(i in actors)
		{
			if(i.data['mobile'])
			{
				isUnits = true;
			}
		}
		if(isUnits)
		{
			for(i in 0...actors.length)
			{
				if(actors[i].data['mobile'])
				{
					units.push(new ActorRepresentative((units.length * actors[i].width) % (actors[i].width * 6) + dashboard.x, Math.floor(units.length / 6) * actors[i].height + dashboard.y, actors[i]));
					uiElements.add(units[units.length-1]);
					
					
					s = new Sprite(new Region(Assets.images.controls,16,0,8,8));
					scaleDelta = buttonWidth/s.width;
					s.setScale(scaleDelta);
					controls.push(new UIElement(dashboard.width - buttonWidth*5, dashboard.y, s));
					controls[controls.length-1].leftClick = function(x:Float,y:Float){dispatchEvent(InputEvent.MOVE, new InputEvent());};
					uiElements.add(controls[controls.length-1]);
					
					s = new Sprite(new Region(Assets.images.controls,8,0,8,8));
					scaleDelta = buttonWidth/s.width;
					s.setScale(scaleDelta);
					controls.push(new UIElement(dashboard.width - buttonWidth*4, dashboard.y, s));
					controls[controls.length-1].leftClick = function(x:Float,y:Float){dispatchEvent(InputEvent.STOP, new InputEvent());};
					uiElements.add(controls[controls.length-1]);
					
					if(actors[i].data.exists('attacks') && actors[i].data.get('attacks').length > 0)
					{
						s = new Sprite(new Region(Assets.images.controls,0,0,8,8));
						scaleDelta = buttonWidth/s.width;
						s.setScale(scaleDelta);
						controls.push(new UIElement(dashboard.width - buttonWidth*3, dashboard.y, s));
						controls[controls.length-1].leftClick = function(x:Float,y:Float){dispatchEvent(InputEvent.ATTACK, new InputEvent());};
						uiElements.add(controls[controls.length-1]);
					}
					if(actors[i].data.exists('buildings') && actors[i].data.get('buildings').length > 0)
					{
						dataArray = actors[i].data['buildings'];
						for(j in dataArray)
						{
							d = Data.dataMap['buildings'][j.name];
							if(buttonNames.indexOf(j.name) == -1)
							{
								buttonNames.push(j.name);
								s = new Sprite(new Region(Reflect.field(Assets.images, d['image']),0,0,d['width'],d['height']));
								scaleDelta = buttonWidth/s.width;
								s.setScale(scaleDelta);
								controls.push(new UIElement(dashboard.width - buttonWidth*5 + (controls.length) % 4 * buttonWidth, dashboard.y + Math.floor((controls.length) / 4) * buttonWidth, s));
								controls[controls.length-1].setSizeAuto();
								
								controls[controls.length - 1].leftClick = function(x:Float,y:Float) 
								{		
									if(actors[i].team.resources >= d['cost'])
									{
										actors[i].eventDispatcher.dispatchEvent(SelectBuildLocationEvent.SELECT, new SelectBuildLocationEvent(actors[i],j.name));
										
									}
								};
								uiElements.add(controls[controls.length-1]);
							}
						}
					}
				}
			}
		}
		else //buildings
		{
			for(i in 0...actors.length)
			{
				units.push(new ActorRepresentative((i * actors[i].width) % (actors[i].width * 6) + dashboard.x, Math.floor(i / 6) * actors[i].height + dashboard.y, actors[i]));
				uiElements.add(units[i]);
					
				if(actors[i].data['units'])
				{
					dataArray = actors[i].data['units'];
					for(j in dataArray)
					{
						d = Data.dataMap['units'][j.name];
						s = new Sprite(new Region(Reflect.field(Assets.images, d['image']),0,0,d['width'],d['height']));
						scaleDelta = buttonWidth/s.width;
						s.setScale(scaleDelta);
						controls.push(new UIElement(dashboard.width - buttonWidth*5 + controls.length % 4 * buttonWidth, dashboard.y + Math.floor(controls.length / 4) * buttonWidth, s));
						controls[controls.length-1].setSizeAuto();
						
						controls[controls.length - 1].leftClick = function(x:Float,y:Float) 
						{
							actors[i].eventDispatcher.dispatchEvent(QueueEvent.QUEUE, new QueueEvent(j));
						};
						uiElements.add(controls[controls.length-1]);
					}
				}
			}
		}
		if(units.length > 0)
		{
			focusUnit = units[0].clone((units[0].width * 8), dashboard.y, 4, 4);
			uiElements.add(focusUnit);
		}
		uiElements.apply(Sdg.screen.add);
	}

	public function killUnit(e:KillEvent)
	{
		var uiElemDied = false;
		for(i in units)
		{
			if(e.actor == i.actor)
			{
				uiElements.remove(i);
				units.remove(i);
				i.kill();
				uiElemDied = true;
				break;
			}
		}
		if(uiElemDied)
		{
			for(i in 0...units.length)
			{
				units[i].x = (i * 8) % 48 + dashboard.x;
				units[i].y = Math.floor(i/6)*8 + dashboard.y;
			}
		}
	}

	public function centerOnActor(e:CenterOnUnitEvent)
	{	
		Sdg.screen.camera.x = e.actor.x - Sdg.screen.camera.halfWidth;
		Sdg.screen.camera.y = e.actor.y - Sdg.screen.camera.halfHeight;
		
		if(Sdg.screen.camera.x < 0) 
			Sdg.screen.camera.x = 0; 
		else if(Sdg.screen.camera.x > Sdg.screen.camera.width + Sdg.gameWidth) 
			Sdg.screen.camera.x = Sdg.gameWidth - Sdg.screen.camera.width; 

		if(Sdg.screen.camera.y < 0) 
			Sdg.screen.camera.y = 0; 
		else if(Sdg.screen.camera.y > Sdg.screen.camera.height + Sdg.gameHeight) 
			Sdg.screen.camera.y = Sdg.gameHeight - Sdg.screen.camera.width; 
	}
	
	public function updateMouseXY(x:Float, y:Float)
	{
		if(buildingToBeBuilt != null)
		{
			buildingToBeBuilt.x = (x - x%8);
			buildingToBeBuilt.y = (y - y%8);
		}
	}
	
	public function setBuildingToBuild(e:SelectBuildLocationEvent)
	{
		var o = new Object();
		var a = Assets.images;
		var image = Reflect.field(Assets.images, e.bData['image']);
		o.graphic = new Sprite(new Region(image, 0, 0, e.bData['width'], e.bData['height']));
		o.graphic.alpha =.5;
		Sdg.screen.add(o);
		buildingToBeBuilt = o;
	}
	
	public function clearBuilding()
	{
		Sdg.screen.remove(buildingToBeBuilt);
		buildingToBeBuilt = null;
	}
	
	public function close()
	{
		if(buildingToBeBuilt != null) 
			clearBuilding();
		uiElements.removeFromScreen();
		uiElements.objects = [];
		Sdg.screen.remove(dashboard);
		dashboard = null;
		units = [];
		focusUnit = null;
		for(i in controls)
		{
			Sdg.screen.remove(i);
		}
		controls = [];
		removeEvent(KillEvent.KILL, killUnit);
		removeEvent(CenterOnUnitEvent.CENTER, centerOnActor);
		removeEvent(SelectBuildLocationEvent.SELECT, setBuildingToBuild);
	}
}