
clean:
	find . -name '*~' -type f -delete

test:
	script/atlas test

commit:	clean test
	git commit -a

push:
	git push -u origin master

tables:
	script/init-database
			