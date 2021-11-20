package editors;

import ui.FlxVirtualPad;
import flixel.addons.ui.FlxUIButton;
import lime.utils.Assets;
import openfl.utils.Assets;
import openfl.utils.Assets;
#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.system.FlxSound;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.ui.FlxButton;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import flash.net.FileFilter;
import haxe.Json;
import DialogueBoxPsych;
import lime.system.Clipboard;
#if sys
import sys.io.File;
#end

using StringTools;

class DialogueEditorState extends MusicBeatState
{
	var character:DialogueCharacter;
	var box:FlxSprite;
	var daText:Alphabet;

	var selectedText:FlxText;
	var animText:FlxText;

	var defaultLine:DialogueLine;
	var dialogueFile:DialogueFile = null;
	var _pad:FlxVirtualPad;

	var key_teste:FlxUIButton;

	var key_menos:FlxUIButton;

	override function create() {

		persistentUpdate = persistentDraw = true;
		FlxG.camera.bgColor = FlxColor.fromHSL(0, 0, 0.5);

		defaultLine = {
			portrait: DialogueCharacter.DEFAULT_CHARACTER,
			expression: 'talk',
			text: DEFAULT_TEXT,
			boxState: DEFAULT_BUBBLETYPE,
			speed: 0.05
		};

		dialogueFile = {
			dialogue: [
				copyDefaultLine()
			]
		};
		
		character = new DialogueCharacter();
		character.scrollFactor.set();
		add(character);

		box = new FlxSprite(70, 370);
		box.frames = Paths.getSparrowAtlas('speech_bubble');
		box.scrollFactor.set();
		box.antialiasing = ClientPrefs.globalAntialiasing;
		box.animation.addByPrefix('normal', 'speech bubble normal', 24);
		box.animation.addByPrefix('angry', 'AHH speech bubble', 24);
		box.animation.addByPrefix('center', 'speech bubble middle', 24);
		box.animation.addByPrefix('center-angry', 'AHH Speech Bubble middle', 24);
		box.animation.play('normal', true);
		box.setGraphicSize(Std.int(box.width * 0.9));
		box.updateHitbox();
		add(box);

		addEditorBox();
		FlxG.mouse.visible = true;

		var addLineText:FlxText = new FlxText(10, 10, FlxG.width - 20, 'Aperte O ou - para remover a fala atual, Aperte P ou + para adicionar uma fala nova.', 8);
		addLineText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		addLineText.scrollFactor.set();
		add(addLineText);

		selectedText = new FlxText(10, 32, FlxG.width - 20, '', 8);
		selectedText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		selectedText.scrollFactor.set();
		add(selectedText);

		animText = new FlxText(10, 62, FlxG.width - 20, '', 8);
		animText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		animText.scrollFactor.set();
		add(animText);
		
		changeText();

		addVirtualPad(FULL, NONE);

		super.create();
	}

	var UI_box:FlxUITabMenu;
	function addEditorBox() {
		var tabs = [
			{name: 'Dialogue Line', label: 'Dialogue Line'},
		];
		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.resize(250, 190);
		UI_box.x = FlxG.width - UI_box.width - 10;
		UI_box.y = 10;
		UI_box.scrollFactor.set();
		UI_box.alpha = 0.8;
		addDialogueLineUI();
		add(UI_box);
	}

	var characterInputText:FlxUIInputText;
	var lineInputText:FlxUIInputText;
	var angryCheckbox:FlxUICheckBox;
	var speedStepper:FlxUINumericStepper;
	function addDialogueLineUI() {
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Dialogue Line";

		key_teste = new FlxUIButton(60, 200, "-", function() {
			dialogueFile.dialogue.remove(dialogueFile.dialogue[curSelected]);
			if(dialogueFile.dialogue.length < 1) //You deleted everything, dumbo!
			{
				dialogueFile.dialogue = [
					copyDefaultLine()
				];
			}
			changeText();
		});
        key_teste.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");
		key_teste.resize(125,50);
        key_teste.alpha = 0.75;
        add(key_teste);

		key_menos = new FlxUIButton(60, (key_teste.y + key_teste.height + 25), "+", function() {
			dialogueFile.dialogue.insert(curSelected + 1, copyDefaultLine());
			changeText(1);
		});
        key_menos.setLabelFormat("VCR OSD Mono",24,FlxColor.BLACK,"center");
		key_menos.resize(125,50);
        key_menos.alpha = 0.75;
        add(key_menos);

		characterInputText = new FlxUIInputText(10, 20, 80, DialogueCharacter.DEFAULT_CHARACTER, 8);
		characterInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		blockPressWhileTypingOn.push(characterInputText);

		speedStepper = new FlxUINumericStepper(10, characterInputText.y + 40, 0.005, 0.05, 0, 0.5, 3);

		angryCheckbox = new FlxUICheckBox(speedStepper.x + 120, speedStepper.y, null, null, "Angry Textbox", 200);
		angryCheckbox.callback = function()
		{
			updateTextBox();
			dialogueFile.dialogue[curSelected].boxState = (angryCheckbox.checked ? 'angry' : 'normal');
		};
		
		lineInputText = new FlxUIInputText(10, speedStepper.y + 45, 200, DEFAULT_TEXT, 8);
		lineInputText.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		blockPressWhileTypingOn.push(lineInputText);

		var loadButton:FlxButton = new FlxButton(20, lineInputText.y + 30, "Load Dialogue", function() {
			loadDialogue();
		});
		var saveButton:FlxButton = new FlxButton(loadButton.x + 120, loadButton.y, "Save Dialogue", function() {
			saveDialogue();
		});

		tab_group.add(new FlxText(10, speedStepper.y - 18, 0, 'Interval/Speed (ms):'));
		tab_group.add(new FlxText(10, characterInputText.y - 18, 0, 'Character:'));
		tab_group.add(new FlxText(10, lineInputText.y - 18, 0, 'Text:'));
		tab_group.add(characterInputText);
		tab_group.add(angryCheckbox);
		tab_group.add(speedStepper);
		tab_group.add(lineInputText);
		tab_group.add(lineInputText);
		tab_group.add(loadButton);
		tab_group.add(saveButton);
		UI_box.addGroup(tab_group);
	}

	function copyDefaultLine():DialogueLine {
		var copyLine:DialogueLine = {
			portrait: defaultLine.portrait,
			expression: defaultLine.expression,
			text: defaultLine.text,
			boxState: defaultLine.boxState,
			speed: defaultLine.speed
		};
		return copyLine;
	}

	function updateTextBox() {
		box.flipX = false;
		var isAngry:Bool = angryCheckbox.checked;
		var anim:String = isAngry ? 'angry' : 'normal';

		switch(character.jsonFile.dialogue_pos) {
			case 'left':
				box.flipX = true;
			case 'center':
				if(isAngry) {
					anim = 'center-angry';
				} else {
					anim = 'center';
				}
		}
		box.animation.play(anim, true);
		DialogueBoxPsych.updateBoxOffsets(box);
	}

	function reloadCharacter() {
		if(character != null) {
		character.frames = Paths.getSparrowAtlas('dialogue/' + character.jsonFile.image);
		character.jsonFile = character.jsonFile;
		character.reloadAnimations();
		character.setGraphicSize(Std.int(character.width * DialogueCharacter.DEFAULT_SCALE * character.jsonFile.scale));
		character.updateHitbox();
		character.x = DialogueBoxPsych.LEFT_CHAR_X;
		character.y = DialogueBoxPsych.DEFAULT_CHAR_Y;

		switch(character.jsonFile.dialogue_pos) {
			case 'right':
				character.x = FlxG.width - character.width + DialogueBoxPsych.RIGHT_CHAR_X;
			
			case 'center':
				character.x = FlxG.width / 2;
				character.x -= character.width / 2;
		}
		character.x += character.jsonFile.position[0];
		character.y += character.jsonFile.position[1];
		character.playAnim(); //Plays random animation
		characterAnimSpeed();

		if(character.animation.curAnim != null) {
			animText.text = 'Animacao: ' + character.jsonFile.animations[curAnim].anim + ' (' + (curAnim + 1) +' / ' + character.jsonFile.animations.length + ') - Aperte cima/baixo para trocar a expressao';
		}} else {
			animText.text = 'Escreva o nome certo do boneco';
		}
	}

	private static var DEFAULT_TEXT:String = "kek";
	private static var DEFAULT_SPEED:Float = 0.05;
	private static var DEFAULT_BUBBLETYPE:String = "normal";
	function reloadText(speed:Float = 0.05) {
		if(daText != null) {
			daText.killTheTimer();
			daText.kill();
			remove(daText);
			daText.destroy();
		}

		if(Math.isNaN(speed) || speed < 0.001) speed = 0.0;

		var textToType:String = lineInputText.text;
		if(textToType == null || textToType.length < 1) textToType = ' ';
		daText = new Alphabet(DialogueBoxPsych.DEFAULT_TEXT_X, DialogueBoxPsych.DEFAULT_TEXT_Y, textToType, false, true, speed, 0.7);
		add(daText);

		if(speed > 0) {
			if(character.jsonFile.animations.length > curAnim && character.jsonFile.animations[curAnim] != null) {
				character.playAnim(character.jsonFile.animations[curAnim].anim);
			}
			characterAnimSpeed();
		}

		#if desktop
		// Updating Discord Rich Presence
		var rpcText:String = lineInputText.text;
		if(rpcText == null || rpcText.length < 1) rpcText = '(Empty)';
		if(rpcText.length < 3) rpcText += '  '; //Fixes a bug on RPC that triggers an error when the text is too short
		DiscordClient.changePresence("Dialogue Editor", rpcText);
		#end
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
		if(id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) {
			if(sender == characterInputText) {
				if (Assets.exists(Paths.image('dialogue/' + sender), IMAGE)) {
				character.reloadCharacterJson(characterInputText.text);
				reloadCharacter();
				updateTextBox();

				if(character.jsonFile.animations.length > 0) {
					curAnim = 0;
					if(character.jsonFile.animations.length > curAnim && character.jsonFile.animations[curAnim] != null) {
						character.playAnim(character.jsonFile.animations[curAnim].anim, daText.finishedText);
						animText.text = 'Animacao: ' + character.jsonFile.animations[curAnim].anim + ' (' + (curAnim + 1) +' / ' + character.jsonFile.animations.length + ') - Aperte cima/baixo para trocar a expressao';
					}} else {
						animText.text = 'Sem personagens por enquanto';
					}
					characterAnimSpeed();
				}
				dialogueFile.dialogue[curSelected].portrait = characterInputText.text;
			} else if(sender == lineInputText) {
				reloadText(0);
				dialogueFile.dialogue[curSelected].text = lineInputText.text;
			}
		} else if(id == FlxUINumericStepper.CHANGE_EVENT && (sender == speedStepper)) {
			reloadText(speedStepper.value);
			dialogueFile.dialogue[curSelected].speed = speedStepper.value;
			if(Math.isNaN(dialogueFile.dialogue[curSelected].speed) || dialogueFile.dialogue[curSelected].speed == null || dialogueFile.dialogue[curSelected].speed < 0.001) {
				dialogueFile.dialogue[curSelected].speed = 0.0;
			}
		}
	}

	var curSelected:Int = 0;
	var curAnim:Int = 0;
	var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	var transitioning:Bool = false;
	override function update(elapsed:Float) {
		if(transitioning) {
			super.update(elapsed);
			return;
		}

		if(character.animation.curAnim != null) {
			if(daText.finishedText) {
				if(character.animationIsLoop() && character.animation.curAnim.finished) {
					character.playAnim(character.animation.curAnim.name, true);
				}
			} else if(character.animation.curAnim.finished) {
				character.animation.curAnim.restart();
			}
		}

		var blockInput:Bool = false;
		for (inputText in blockPressWhileTypingOn) {
			if(inputText.hasFocus) {
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];
				blockInput = true;

				if(FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.V && Clipboard.text != null) { //Copy paste
					inputText.text = ClipboardAdd(inputText.text);
					inputText.caretIndex = inputText.text.length;
					getEvent(FlxUIInputText.CHANGE_EVENT, inputText, null, []);
				}
				if(FlxG.keys.justPressed.ENTER) {
					if(inputText == lineInputText) {
						inputText.text += '\\n';
						inputText.caretIndex += 2;
					} else {
						inputText.hasFocus = false;
					}
				}
				break;
			}
		}

		if(!blockInput) {
			FlxG.sound.muteKeys = TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
			if(FlxG.keys.justPressed.SPACE) {
				reloadText(speedStepper.value);
			}
			#if android
			var androidback = FlxG.android.justReleased.BACK;
			#else
			var androidback = false;
			#end

			if(FlxG.keys.justPressed.ESCAPE || androidback) {
				MusicBeatState.switchState(new editors.MasterEditorMenu());
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 1);
				transitioning = true;
			}
			var negaMult:Array<Int> = [1, -1];
			var controlAnim:Array<Bool> = [controls.UI_UP_P, controls.UI_DOWN_P];
			var controlText:Array<Bool> = [controls.UI_RIGHT_P, controls.UI_LEFT_P];
			for (i in 0...controlAnim.length) {
				if(controlAnim[i] && character.jsonFile.animations.length > 0) {
					curAnim += negaMult[i];
					if(curAnim < 0) curAnim = character.jsonFile.animations.length - 1;
					else if(curAnim >= character.jsonFile.animations.length) curAnim = 0;

					var animToPlay:String = character.jsonFile.animations[curAnim].anim;
					if(character.dialogueAnimations.exists(animToPlay)) {
						character.playAnim(animToPlay, daText.finishedText);
						dialogueFile.dialogue[curSelected].expression = animToPlay;
					}
					animText.text = 'Animacao: ' + animToPlay + ' (' + (curAnim + 1) +' / ' + character.jsonFile.animations.length + ') - Aperte cima/baixo para trocar a expressao';
				}
				if(controlText[i]) {
					changeText(negaMult[i]);
				}
			}

			if(FlxG.keys.justPressed.O) {
				dialogueFile.dialogue.remove(dialogueFile.dialogue[curSelected]);
				if(dialogueFile.dialogue.length < 1) //You deleted everything, dumbo!
				{
					dialogueFile.dialogue = [
						copyDefaultLine()
					];
				}
				changeText();
			} else if(FlxG.keys.justPressed.P) {
				dialogueFile.dialogue.insert(curSelected + 1, copyDefaultLine());
				changeText(1);
			}
		}
		super.update(elapsed);
	}

	function changeText(add:Int = 0) {
		curSelected += add;
		if(curSelected < 0) curSelected = dialogueFile.dialogue.length - 1;
		else if(curSelected >= dialogueFile.dialogue.length) curSelected = 0;

		var curDialogue:DialogueLine = dialogueFile.dialogue[curSelected];
		characterInputText.text = curDialogue.portrait;
		lineInputText.text = curDialogue.text;
		angryCheckbox.checked = (curDialogue.boxState == 'angry');
		speedStepper.value = curDialogue.speed;

		curAnim = 0;
		character.reloadCharacterJson(characterInputText.text);
		reloadCharacter();
		updateTextBox();
		reloadText(curDialogue.speed);

		var leLength:Int = character.jsonFile.animations.length;
		if(leLength > 0) {
			for (i in 0...leLength) {
				var leAnim:DialogueAnimArray = character.jsonFile.animations[i];
				if(leAnim != null && leAnim.anim == curDialogue.expression) {
					curAnim = i;
					break;
				}
			}
			character.playAnim(character.jsonFile.animations[curAnim].anim, daText.finishedText);
			animText.text = 'Animacao: ' + character.jsonFile.animations[curAnim].anim + ' (' + (curAnim + 1) +' / ' + leLength + ') - Aperte cima/baixo para trocar a expressao';
		} else {
			animText.text = 'ERROR! NO ANIMATIONS FOUND';
		}
		characterAnimSpeed();

		selectedText.text = 'Fala: (' + (curSelected + 1) + ' / ' + dialogueFile.dialogue.length + ') - Aperte para direita/esquerda para trocar entre as falas';
	}

	function characterAnimSpeed() {
		if(character.animation.curAnim != null) {
			var speed:Float = speedStepper.value;
			var rate:Float = 24 - (((speed - 0.05) / 5) * 480);
			if(rate < 12) rate = 12;
			else if(rate > 48) rate = 48;
			character.animation.curAnim.frameRate = rate;
		}
	}

	function ClipboardAdd(prefix:String = ''):String {
		if(prefix.toLowerCase().endsWith('v')) //probably copy paste attempt
		{
			prefix = prefix.substring(0, prefix.length-1);
		}

		var text:String = prefix + Clipboard.text.replace('\n', '');
		return text;
	}

	var _file:FileReference = null;
	function loadDialogue() {
		var jsonFilter:FileFilter = new FileFilter('JSON', 'json');
		_file = new FileReference();
		_file.addEventListener(Event.SELECT, onLoadComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([jsonFilter]);
	}

	function onLoadComplete(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		var fullPath:String = null;
		var jsonLoaded = cast Json.parse(Json.stringify(_file)); //Exploit(???) for accessing a private variable
		if(jsonLoaded.__path != null) fullPath = jsonLoaded.__path; //I'm either a genious or dangerously dumb

		if(fullPath != null) {
			var rawJson:String = Paths.json('test' + '/dialogue');
			if(rawJson != null) {
				var loadedDialog:DialogueFile = cast Json.parse(rawJson);
				if(loadedDialog.dialogue != null && loadedDialog.dialogue.length > 0) //Make sure it's really a dialogue file
				{
					var cutName:String = _file.name.substr(0, _file.name.length - 5);
					//trace("Successfully loaded file: " + cutName);
					dialogueFile = loadedDialog;
					changeText();
					_file = null;
					return;
				}
			}
		}
		_file = null;
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onLoadCancel(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		//trace("Cancelled file loading.");
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onLoadError(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file = null;
		//trace("Problem loading file");
	}

	function saveDialogue() {
		var data:String = Json.stringify(dialogueFile, "\t");

		openfl.system.System.setClipboard(data.trim());

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, "dialogue.json");
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}
}