#!/usr/bin/env python3

import json
import sys

if len(sys.argv) == 1:
    print("[0] [name] [out]".format(sys.argv[0]))
    sys.exit(0)

with open(sys.argv[1]) as f:
    data = json.loads(f.read())

frame_tags = data["meta"]["frameTags"]

definitions = {
    "fill": [ "fill" ],
    "skins": [
        "skins"+str(i) for i in range(0, 3)
    ],
    "eyes": [
        "eyes"+str(i) for i in range(0, 2)
    ],
}
frames = data["frames"]
processed_frames = {}

frame_tags = { tag["name"]: tag for tag in frame_tags }
"""
for tag in frame_tags: # for every tag, let's gather them first
    if tag["name"] not in definition:
        print("{} not found".format(tag["name"]))
        continue

    filenames = definition[tag["name"]]
    start = tag["from"]
    end = tag["to"]
    ind = 0
    for i in range(start, end+1):
        d = frames[i]
        processed_frames[filenames[ind]] = {
            "x": d["frame"]["x"],
            "y": d["frame"]["y"],
            "w": d["frame"]["w"],
            "h": d["frame"]["h"],
        }
        ind += 1
"""
for key, definition in definitions.items():
    # simple conversion
    if isinstance(definition, list):
        if key not in frame_tags:
            raise Exception("Frame Tags not found for {}".format(key))
        frame_tag = frame_tags[key]
        frame_len = frame_tag["to"] - frame_tag["from"] + 1

        if len(definition) != frame_len:
            raise Exception("Frame Length is not the same as Definitions.")

        ind = 0
        for i in range(frame_tag["from"], frame_tag["to"]+1):
            d = frames[i]
            processed_frames[definition[ind]] = {
                "x": d["frame"]["x"],
                "y": d["frame"]["y"],
                "w": d["frame"]["w"],
                "h": d["frame"]["h"],
                "r": 0,
            }
            ind += 1

    else:
        files = definition.get("files")
        for f in files:
            name = f["name"]
            frame_key = f.get("key") or key
            target_frame_ind = f["frame"] + frame_tags[frame_key]["from"]
            d = frames[target_frame_ind]
            p_frame = {
                "x": d["frame"]["x"],
                "y": d["frame"]["y"],
                "w": d["frame"]["w"],
                "h": d["frame"]["h"],
                "r": 0,
            }
            if f.get("r"):
                p_frame["r"] = f.get("r")
            processed_frames[name] = p_frame


with open(sys.argv[2], "w") as f:
    print(json.dumps(processed_frames, indent=2), file=f)


