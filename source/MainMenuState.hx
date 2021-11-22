package;

import flixel.addons.ui.FlxUIButton;
import Achievements;
import editors.MasterEditorMenu;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;

using StringTools;
#if desktop
import Discord.DiscordClient;
#end

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.4.2'; //This is also used for Discord RPC
	public static var curSelected:Int = 7;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;
	
	var optionShit:Array<String> = ['story_mode', 'freeplay', #if ACHIEVEMENTS_ALLOWED 'awards', #end 'credits', #if desktop 'donate', #end 'options'];

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;

	var storybotao:FlxUIButton;

	var freebotao:FlxUIButton;

	var creditbotao:FlxUIButton;

	var opcaobotao:FlxUIButton;

	var awardsbotao:FlxUIButton;

	var secreto:FlxUIButton;

	var checkiftouch:Bool = false;

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement);
		FlxCamera.defaultCameras = [camGame];

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		secreto = new FlxUIButton(0, 650, "", function() {
			FlxG.sound.play(Paths.sound('secretSound')); //Porque é legal! Apenas!
			MusicBeatState.switchState(new TelaAntiSafado());
		});
        secreto.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");
		secreto.resize(275,120);
        secreto.alpha = 0.75;
        add(secreto);
	
		storybotao = new FlxUIButton(0, 30, "APAGOU", function() {
			curSelected = 0;
			if(curSelected == 0){selectedSomethin = true; checkiftouch = true;}
		});
        storybotao.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");
		storybotao.resize(500,120);
        storybotao.alpha = 0.75;
		storybotao.screenCenter(X);
        add(storybotao);

		freebotao = new FlxUIButton(0, 170, "OS", function() {
			curSelected = 1;
			if(curSelected == 1){selectedSomethin = true; checkiftouch = true;}
		});
        freebotao.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");
		freebotao.resize(420,120);
        freebotao.alpha = 0.75;
		freebotao.screenCenter(X);
        add(freebotao);

		creditbotao = new FlxUIButton(0, 450, "Né", function() {
			curSelected = 3;
			if(curSelected == 3){selectedSomethin = true; checkiftouch = true;}
			});
		creditbotao.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");
		creditbotao.resize(420,120);
		creditbotao.alpha = 0.75;
		creditbotao.screenCenter(X);
		add(creditbotao);

		opcaobotao = new FlxUIButton(0, 590, "SAFADO", function() {
			curSelected = 4;
			if(curSelected == 4){selectedSomethin = true; checkiftouch = true;}
		});
        opcaobotao.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");
		opcaobotao.resize(420,120);
        opcaobotao.alpha = 0.75;
		opcaobotao.screenCenter(X);
        add(opcaobotao);

		awardsbotao = new FlxUIButton(0, 310, "MENUS", function() {
			curSelected = 2;		
			if(curSelected == 2){selectedSomethin = true; checkiftouch = true;}
					});
		awardsbotao.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");
		awardsbotao.resize(400,120);
		awardsbotao.alpha = 0.75;
		awardsbotao.screenCenter(X);
		add(awardsbotao);

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i * 140)  + offset);
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if(optionShit.length < 6) scr = 0;
			menuItem.scrollFactor.set(0, scr);
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			//menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));
			menuItem.updateHitbox();
		}

		FlxG.camera.follow(camFollowPos, null, 1);

		var versionShit:FlxText = new FlxText(5, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		var versionShit:FlxText = new FlxText(5, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		var versionShit:FlxText = new FlxText(5, FlxG.height - 64, 0, "BS Engine Mobile v 1.0 BETA", 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();


		
		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		if(ClientPrefs.easteregg){
			var achieveID:Int = Achievements.getAchievementIndex('week7_nomiss');
			if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) {
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievemento();
				ClientPrefs.easteregg = false;
				ClientPrefs.saveSettings();
				}
		} //haha omega kek
		#end

		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement() {
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		//trace('Giving achievement "friday_night_play"');
	}
		// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievemento() {
		add(new AchievementObject('week7_nomiss', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		//trace('Giving achievement "friday_night_play"');
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 5.6, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));


			if (checkiftouch)
			{
				if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					FlxG.sound.play(Paths.sound('confirmMenu'));

					checkiftouch = false; //This should be enough

					menuItems.forEach(function(spr:FlxSprite)
					{
						if (curSelected != spr.ID)
						{
							FlxTween.tween(spr, {alpha: 0}, 0.4, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						}
						else
						{
							FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
							{
								var daChoice:String = optionShit[curSelected];

								switch (daChoice)
								{
									case 'story_mode':
										MusicBeatState.switchState(new StoryMenuState());
									case 'freeplay':
										MusicBeatState.switchState(new FreeplayState());
									case 'awards':
										MusicBeatState.switchState(new AchievementsMenuState());
									case 'credits':
										MusicBeatState.switchState(new CreditsState());
									case 'options':
										MusicBeatState.switchState(new OptionsState());
								}
							});
						}
					});
				}
			}
			else if (FlxG.android.justReleased.BACK)
			{
				MusicBeatState.switchState(new MasterEditorMenu());
			}

		super.update(elapsed);

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.screenCenter(X);
		});
	}

	function changeItem(huh:Int = 0)
	{

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.offset.y = 0;
			spr.updateHitbox();
		});
	}
}
