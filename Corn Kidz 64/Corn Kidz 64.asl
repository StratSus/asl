// Made by Stratus
// asl-help by ero (https://github.com/just-ero/asl-help/)

state("Corn Kidz 64") {}

startup {
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Unity");

    settings.Add("start", true, "Starting splits");
    settings.Add("start_file", true, "Start on new file", "start");
    settings.Add("start_mirror", false, "Start on entering a mirror challenge", "start");
    settings.Add("start_tower", false, "Start on entering Tower", "start");
    settings.Add("start_anxiety", false, "Start on entering Anxiety Tower", "start");
    settings.Add("start_any", false, "Start on any selected split point", "start");
    settings.SetToolTip("start_any", "Will start the timer on any checked split point. Recommended for use in ILs and segments.");

    settings.Add("area", true, "Area splits: ");
    settings.Add("split_parkEnter", true, "Enter Lexi's Monster Park", "area");
    settings.Add("split_hollowEnter", true, "Enter Wollow's Hollow", "area");
    settings.Add("split_towerEnter", true, "Enter Tower", "area");
    settings.Add("split_anxietyEnter", true, "Enter Anxiety Tower", "area");
    settings.Add("split_secretEnter", true, "Enter Some Other Place", "area");
    settings.Add("split_testEnter", true, "Enter Test Zone", "area");

    settings.Add("level", false, "Level splits: ");
    settings.Add("split_level2", false, "Level 2", "level");
    settings.Add("split_level3", false, "Level 3", "level");
    settings.Add("split_level4", false, "Level 4", "level");
    settings.Add("split_level5", false, "Level 5", "level");
    settings.Add("split_level6", false, "Level 6", "level");

    settings.Add("upgrade", true, "Upgrade splits: ");
    settings.Add("split_ugDrill", true, "Drill", "upgrade");
    settings.Add("split_ugWarp", true, "Fall Warp", "upgrade");

    settings.Add("split_credits", true, "Split on reaching credits");

    settings.Add("split_mirror", false, "Split on completing a mirror challenge");
    settings.SetToolTip("split_mirror", "Will split regardless of whether the challenge was completed successfully or not. Not recommended for full game runs.");

    settings.Add("misc", false, "Misc.");
    settings.Add("log_debug", false, "Log variable updates to debug", "misc");
    settings.SetToolTip("log_debug", "Recommended to leave this off unless you're developing the autosplitter.");
}

init {
    vars.Helper.TryLoad = (Func<dynamic, bool>)(mono => {
        vars.Helper["gameTime"] = mono.Make<int>("GameCtrl", "instance", "data", "gameTime");
        vars.Helper["world"] = mono.Make<int>("GameCtrl", "instance", "currentWorld");
        vars.Helper["cpScene"] = mono.MakeString("GameCtrl", "instance", "checkpointScene");
        vars.Helper["fading"] = mono.Make<bool>("GameCtrl", "instance", "bFading");
        vars.Helper["level"] = mono.Make<int>("GameCtrl", "instance", "data", "currentLvl");
        vars.Helper["switches"] = mono.MakeArray<bool>("GameCtrl", "instance", "data", "switches");
        vars.Helper["items"] = mono.MakeArray<bool>("GameCtrl", "instance", "data", "items");
        vars.Helper["upgrades"] = mono.MakeArray<bool>("GameCtrl", "instance", "data", "upgrades");
        vars.Helper["ints"] = mono.MakeArray<int>("GameCtrl", "instance", "data", "ints");
        vars.Helper["cranks"] = mono.MakeArray<int>("GameCtrl", "instance", "data", "cranks");
        vars.Helper["lvlItems1"] = mono.MakeArray<int>("GameCtrl", "instance", "data", "lvlItems1");
        return true;
    });

    vars.startTime = 0;
    vars.queueSplit = false;

    vars.PrintArrayChanges = (Action<Array, Array, string>)((oldArr, newArr, name) => {
        if(!Enumerable.SequenceEqual(oldArr.Cast<object>(), newArr.Cast<object>())) {
            for(int i = 0; i < newArr.Length; i++) {
                var oldVal = oldArr.GetValue(i);
                var newVal = newArr.GetValue(i);

                if(!Equals(oldVal, newVal)) {
                    print(name + "[" + i.ToString() + "] updated: " + oldVal.ToString() + " -> " + newVal.ToString());
                }
            }
        }
    });
}

update {
    if(settings["log_debug"]) {
        if(old.world != current.world) {
            print("world updated: " + old.world.ToString() + " -> " + current.world.ToString());
        }

        if(old.cpScene != current.cpScene) 
            print("checkpointScene updated: '" + old.cpScene + "' -> '" + current.cpScene + "'");
            
        vars.PrintArrayChanges(old.switches, current.switches, "switches");
        vars.PrintArrayChanges(old.items, current.items, "items");
        vars.PrintArrayChanges(old.upgrades, current.upgrades, "upgrades");
        vars.PrintArrayChanges(old.ints, current.ints, "ints");
        vars.PrintArrayChanges(old.cranks, current.cranks, "cranks");
        vars.PrintArrayChanges(old.lvlItems1, current.lvlItems1, "lvlItems1");
    }
    
    if(timer.CurrentPhase == TimerPhase.Ended || timer.CurrentPhase == TimerPhase.Paused || (timer.CurrentPhase == TimerPhase.NotRunning && !settings["start_any"])) 
        return;

    if(old.world != current.world) {
        if(settings["split_credits"] && current.world == -102)
            vars.queueSplit = true;

        else if(settings["split_mirror"] && old.world == -1)
            vars.queueSplit = true;
    }
    
    if (old.cpScene != current.cpScene) {
        if(settings["split_parkEnter"] && current.cpScene == "TutorialWorld01")
            vars.queueSplit = true;

        else if(settings["split_hollowEnter"] && current.cpScene == "Wolloh's Hollow")
            vars.queueSplit = true;

        else if(settings["split_towerEnter"] && current.cpScene == "Tower00")
            vars.queueSplit = true;

        else if(settings["split_anxietyEnter"] && current.cpScene == "TowerN00")
            vars.queueSplit = true;

        else if(settings["split_secretEnter"] && current.cpScene == "secretZone00")
            vars.queueSplit = true;
        
        else if(settings["split_testEnter"] && current.cpScene == "TestZoneX")
            vars.queueSplit = true;
    }

    if(old.level != current.level && current.level > 1) {
        if(settings["split_level" + current.level.ToString()]) 
            vars.queueSplit = true;
    }

    if(!Enumerable.SequenceEqual(old.upgrades, current.upgrades)) {
        if(settings["split_ugDrill"] && current.upgrades[1])
            vars.queueSplit = true;
        if(settings["split_ugWarp"] && current.upgrades[2])
            vars.queueSplit = true;
    }
}

isLoading {
    return old.gameTime == current.gameTime;
}

gameTime {
    return TimeSpan.FromSeconds((double) (current.gameTime - vars.startTime) / 30);
}

onStart {
    vars.startTime = current.gameTime;
    if(vars.queueSplit)
        vars.queueSplit = false;
}

onSplit {
    vars.queueSplit = false;
}

start {
    if(settings["start_file"] && current.gameTime == 0 && current.fading)
        return true;
    if(settings["start_mirror"] && old.world != current.world && current.world == -1)
        return true;
    if(settings["start_tower"] && old.cpScene != current.cpScene && current.cpScene == "Tower00")
        return true;
    if(settings["start_anxiety"] && old.cpScene != current.cpScene && current.cpScene == "TowerN00")
        return true;
    if(settings["start_any"]) 
        return vars.queueSplit;
}

split {
    return vars.queueSplit;
}

reset {
    if(settings["reset_fileDelete"] && old.gameTime != 0 && current.gameTime == 0)
        return true;
}
