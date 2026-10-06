APP := build/TextPeek.app

.PHONY: app install clean

app:
	swift build -c release
	rm -rf $(APP)
	mkdir -p $(APP)/Contents/MacOS
	cp .build/release/TextPeek $(APP)/Contents/MacOS/
	cp Info.plist $(APP)/Contents/
	codesign --force --sign - $(APP)

install: app
	pkill -x TextPeek || true
	rm -rf ~/Applications/TextPeek.app
	mkdir -p ~/Applications
	cp -R $(APP) ~/Applications/
	open ~/Applications/TextPeek.app

clean:
	rm -rf .build build
