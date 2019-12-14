CURRENT_DATE=$(date "+%Y-%m-%d")
update:
	./update_archives.R
	
	git add .
	git commit -m "Automatic update: $(CURRENT_DATE)"
	git push
