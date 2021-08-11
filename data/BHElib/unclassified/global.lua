lstg.quit_flag = false  -- checks in game update function, if true then exit the game

---In-game global variables

---player of the game
---
---assumptions: one and only one player; created by createScene() of the game scene, must exist throughout the scene;
player = nil