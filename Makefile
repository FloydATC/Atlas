
clean:
	find . -name '*~' -type f -delete

commit:	clean
	git add $(git ls-files -o --exclude-standard)
	git commit
		