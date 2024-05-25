-- ███╗   ███╗ █████╗ ████████╗██╗  ██╗███████╗██╗  ██╗
-- ████╗ ████║██╔══██╗╚══██╔══╝██║  ██║██╔════╝╚██╗██╔╝
-- ██╔████╔██║███████║   ██║   ███████║█████╗   ╚███╔╝
-- ██║╚██╔╝██║██╔══██║   ██║   ██╔══██║██╔══╝   ██╔██╗
-- ██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║███████╗██╔╝ ██╗
-- ╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
--
-- Regex for equations
--
-- Copyright 2024 ExeVirus
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
--                          Table of Contents
--
--           1. Overview
--           2. Syntax
--           3. Tokenization Implementation
--           4. Mathex-specific Shunting Yard Algorithm
--           5. Mathex Function Definition
--           5. Appendix A: Error Codes and their meaning
--
--         ___ __   __ ___  ___ __   __ ___  ___ __      __
--        / _ \\ \ / /| __|| _ \\ \ / /|_ _|| __|\ \    / /
--       | (_) |\ V / | _| |   / \ V /  | | | _|  \ \/\/ /
--        \___/  \_/  |___||_|_\  \_/  |___||___|  \_/\_/
--
-- Mathex allows you to specify your input validation logic in a
-- human-readable, verfiable, matinainable way, as opposed to putting
-- validation logic in language specific code that is error prone,
-- time-consuming, and highly specific.
--
-- Mathex provides aims to provide the same interface in every language:
-- 
--     mathex("equation", val1, val2,...valN)
--
-- The return value for a *valid* mathex call is either 0 or 1.
-- Negative values indicate an error during processing.
-- The table of supported processing errors are in Appendix A.
--
-- Mathex expects valid IEEE Floating point values for all Value inputs
-- The "equation" systax is as follows:
--
--              ___ __   __ _  _  _____  _   __  __
--             / __|\ \ / /| \| ||_   _|/_\  \ \/ /
--             \__ \ \ V / | .` |  | | / _ \  >  <
--             |___/  |_|  |_|\_|  |_|/_/ \_\/_/\_\
--          (Dare: track # of times you check this section)
--
--    Mathex has 4 different "things" (tokens) in the language:
--
--               1. Numbers      (###.###)
--               2. Variables    (A, B, C, AA, BB, CC, etc.)
--               3. Math Symbols (+-*/^%&|!=,)
--               4. Functions    (min, max, abs, etc.)
--
--                     Whitespace is ignored.
-- 
-- 
-- 
-- 
--
--  _____ ___  _  _____ _  _ ___ ____  _ _____ ___ ___  _  _
-- |_   _/ _ \| |/ / __| \| |_ _|_  / /_\_   _|_ _/ _ \| \| |
--   | || (_) | ' <| _|| .` || | / / / _ \| |  | | (_) | .` |
--   |_| \___/|_|\_\___|_|\_|___/___/_/ \_\_| |___\___/|_|\_|
--               (Fancy term for text->number)

--          _   _    ___  ___  ___ ___ _____ _  _ __  __
--         /_\ | |  / __|/ _ \| _ \_ _|_   _| || |  \/  |
--        / _ \| |_| (_ | (_) |   /| |  | | | __ | |\/| |
--       /_/ \_\____\___|\___/|_|_\___| |_| |_||_|_|  |_|
--              (Spent all 3 brain cells on this one)

--   _____ _  _ ___   ___ _   _ _  _  ___ _____ ___ ___  _  _
--  |_   _| || | __| | __| | | | \| |/ __|_   _|_ _/ _ \| \| |
--    | | | __ | _|  | _|| |_| | .` | (__  | |  | | (_) | .` |
--    |_| |_||_|___| |_|  \___/|_|\_|\___| |_| |___\___/|_|\_|
--                (The thing we came here for)

--          _   ___ ___ ___ _  _ ___ _____  __    _
--         /_\ | _ \ _ \ __| \| |   \_ _\ \/ /   /_\
--        / _ \|  _/  _/ _|| .` | |) | | >  <   / _ \
--       /_/ \_\_| |_| |___|_|\_|___/___/_/\_\ /_/ \_\
--                    (Appendix A: Error Codes)

















