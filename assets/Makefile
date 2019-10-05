
all:
	rm -rf build
	mkdir build
	python3 process_json.py images.json build/images.json
	cp images.png build/images.png
	mkdir build/split
	python3 assets.py crop build/images.json build/images.png build/split/
	python3 assets.py pack build/split build/rejoin
	cp build/rejoin.json ../res/images.json
	cp build/rejoin.png ../res/images.png
