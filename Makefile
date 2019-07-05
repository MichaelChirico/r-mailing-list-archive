CURRENT_DATE=$(date "+%Y-%m-%d")
update:
	./update_archives.R

	git commit -a -m "Automatic update: $(CURRENT_DATE)"
	git push
