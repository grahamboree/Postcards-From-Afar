binaryName = main

all: obj linkfile assemble clean

obj:
	mkdir -p obj
	rm -f ./bin/*.gb

linkfile:
	@echo "#autocreated Linkfile" >> obj/$(binaryName).link
	@echo "#" >> obj/$(binaryName).link
	@echo "#" >> obj/$(binaryName).link
	@echo "[Objects]" >> obj/$(binaryName).link
	@echo "./obj/$(binaryName).obj" >> obj/$(binaryName).link
	@echo "#" >> obj/$(binaryName).link
	@echo "[Output]" >> obj/$(binaryName).link
	@echo "./obj/$(binaryName).gb" >> obj/$(binaryName).link

assemble:
	rgbasm -E -iinc/ -oobj/$(binaryName).obj src/$(binaryName).asm
	rgblink -o obj/$(binaryName).gb -n obj/$(binaryName).sym obj/$(binaryName).obj
	rgbfix -v obj/$(binaryName).gb

clean:
	rm -f ./obj/*.obj

run: all
	wine tools/bgb/bgb.exe obj/$(binaryName).gb
