
clean:
	find . -name '*~' -type f -delete

test:
	script/atlas test

commit:	clean test
	git add $(git ls-files -o --exclude-standard)
	git commit -a

push:
	git push -u origin master
		