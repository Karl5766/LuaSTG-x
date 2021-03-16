---------------------------------------------------------------------------------------------------
---replay_read_write.lua
---desc: Manages replay file read and write interfaces
---modifier:
---------------------------------------------------------------------------------------------------
---replay file structure

---n1: scene 1 replay length in bytes
---scene 1 replay data (player init pos etc.)
---n2
---scene 2 replay data
---...
---n6
---scene 6 replay data
---general replay data (player signature etc.)

---------------------------------------------------------------------------------------------------
---general replay

---num_stage_completed (number)
---final_score (number)
---player_signature (string)
---scene_group_init_state (SceneGroupInitState)

---------------------------------------------------------------------------------------------------
---scene replay

---random_seed (number)
---game_scene_init_state (GameSceneInitState)