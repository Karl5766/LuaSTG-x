-------------------------------------------------------------------------------------------------
---replay_read_write.lua
---desc: Manages replay file read and write interfaces
---modifier:
-------------------------------------------------------------------------------------------------
---brief: replay file structure

---general replay data (player signature etc.)
---n1: scene 1 replay length in bytes
---scene 1 replay data (player init pos etc.)
---n2
---scene 2 replay data
---...
---n6
---scene 6 replay data

-------------------------------------------------------------------------------------------------
---data: general replay

---num_stage_completed (number)
---stage_id_array (table) an array of strings of stage ids
---final_score (table) the score can be large, so it is represented with two numbers {high, low}
---shot_type_id (string)
---player_signature (string)

-------------------------------------------------------------------------------------------------
---data: scene replay

---random_seed (number)
---scene_init_state (SceneInitState)
---player (table) : {
---     x (number),
---     y (number),
---     lives (number),
---     bombs (number),
--- }