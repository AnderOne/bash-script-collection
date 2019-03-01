#!/bin/bash

####################################################################################################
#dsynch $src $dst +d-c+r
####################################################################################################
#+/-d -- разрешить/запретить удаление старых файлов и каталогов;
#+/-c -- разрешить/запретить копирование файлов и каталогов;
#+/-r -- разрешить/запретить замену старых файлов новыми;
####################################################################################################

#Функция разделителя:
function delimiter() {
	local len=$(stty size | sed 's/[0-9]\+ //'); local str=""; for ((i=1; i<$len; ++i)); do str="$1$str"; done
	echo $str
}

#Функция диалога:
function dialog() {
	local ans; read ans; while [ "$ans" != "$1" ] && [ "$ans" != "$2" ]; do read ans; done; echo $ans
}

function delete_all() {
	cd "$dst"; e=$?; if [ $e -ne 0 ]; then echo "ERROR: Can't access to the directory!"; exit $e; fi
	if [ "$arg_d" == '-' ]
	then return
	fi
	for i in $(ls -A "$dst")
	do delete "$i"
	done
	e=$?
	if [ $e -ne 0 ]
	then exit $e
	fi
}

function copy_all() {
	cd "$src"; e=$?; if [ $e -ne 0 ]; then echo "ERROR: Can't access to the directory!"; exit $e; fi
	for i in $(ls -A "$src")
	do copy "$i"
	done
	e=$?
	if [ $e -ne 0 ]
	then exit $e
	fi
}

function delete() {
	local ind=$(echo "$1" | sed 's/^\.\///')
	#Если указан каталог:
	if [ -d "$dst/$ind" ]
	then
		#Если указанный каталог существует в SRC:
		if [ -d "$src/$ind" ]
		then
			for i in $(ls -A "$dst/$ind")
			do delete "$ind/$i"; e=$?; if [ $e -ne 0 ]; then exit $e; fi
			done
			return 0
		fi
		#Запрос на удаление старого каталога:
		if [ -z "$arg_d" ]
		then
			echo "Удалить старый каталог '$dst/$ind'? [y/n]:"
			if [ $(dialog 'y' 'n') == 'y' ]
			then rm -rf "$dst/$ind"
			fi
		elif [ "$arg_d" == "+" ]
		then rm -rfv "$dst/$ind"
		else return 0
		fi
	#Если указан файл:
	elif [ -f "$dst/$ind" ]
	then
		#Если указанный файл существует в SRC:
		if [ -f "$src/$ind" ]; then return 0; fi
		#Запрос на удаление старого файла:
		if [ -z "$arg_d" ]; then
			echo "Удалить старый файл '$dst/$ind'? [y/n]:"
			if [ $(dialog 'y' 'n') == 'y' ]
			then rm -rf "$dst/$ind"
			fi
		elif [ "$arg_d" == "+" ]
		then rm -rfv "$dst/$ind"
		else return 0
		fi
	else
		delimiter '!'
		echo "ERROR: Unknown type of item '$dst/$ind'!"
		delimiter '!'
		exit 1
	fi
	e=$?; if [ $e -ne 0 ]; then exit $e; fi
	delimiter '-'
}

function copy() {
	local ind=$(echo "$1" | sed 's/^\.\///')
	dir=$(dirname "$ind")
	#Если указан каталог:
	if [ -d "$src/$ind" ]
	then
		#Если указанный каталог существует в DST:
		if [ -d "$dst/$ind" ]; then
			for i in $(ls -A "$src/$ind")
			do copy "$ind/$i"; e=$?; if [ $e -ne 0 ]; then exit $e; fi
			done
			return 0
		fi
		#Запрос на копирование нового каталога:
		if [ -z "$arg_c" ]; then
			echo "Копировать каталог '$src/$ind' в '$dst/$ind'? [y/n]:"
			if [ $(dialog 'y' 'n') == 'y' ]
			then cp -a "$src/$ind" "$dst/$ind"
			fi
		elif [ "$arg_c" == "+" ]
		then cp -av "$src/$ind" "$dst/$ind"
		else return 0
		fi
	#Если указан файл:
	elif [ -f "$src/$ind" ]
	then
		#Если указанный файл существует в DST:
		if [ -f "$dst/$ind" ]; then
			if [ "$src/$ind" -nt "$dst/$ind" ]; then
				if [ -z "$arg_r" ]; then
					echo "Заменить файл '$dst/$ind' более новым '$src/$ind'? [y/n]:"
					if [ $(dialog 'y' 'n') == 'y' ]
					then cp -a "$src/$ind" "$dst/$dir"
					fi
				elif [ "$arg_r" == "+" ]
				then cp -av "$src/$ind" "$dst/$dir"
				else return 0
				fi
			else return 0
			fi
		else
			if [ -z "$arg_c" ]; then
				echo "Копировать файл '$src/$ind' в '$dst/$ind'? [y/n]:"
				if [ $(dialog 'y' 'n') == 'y' ]
				then cp -a "$src/$ind" "$dst/$dir"
				fi
			elif [ "$arg_c" == "+" ]
			then cp -av "$src/$ind" "$dst/$dir"
			else return 0
			fi
		fi
	else
		delimiter '!'
		echo "ERROR: Unknown type of item '$src/$ind'!"
		delimiter '!'
		exit 1
	fi
	e=$?; if [ $e -ne 0 ]; then exit $e; fi
	delimiter '-'
}

export -f delimiter dialog delete copy

#Определяем входные параметры:
if [ ! -z "$4" ]
then
	delimiter '!'; echo "ОШИБКА: Слишком много аргументов!"; delimiter '!'
	exit 1
fi

if [ -z "$2" ]
then
	delimiter '!'; echo "ОШИБКА: Слишком мало аргументов!"; delimiter '!'
	exit 1
fi

declare -A H
if [[ ! "$3" =~ ^([+-][dcr])*$ ]]
then
	delimiter '!'; echo "ОШИБКА: Некорректный параметр '$3'!"
	delimiter '!'
	exit 1
fi
for a in $(echo "$3" | grep -o '[+-][dcr]')
do
	H[${a:1:1}]=${a:0:1}
done
arg_d=${H["d"]}
arg_r=${H["r"]}
arg_c=${H["c"]}
unset H

src=$(readlink -f "$1" | sed 's/\/*$//')
dst=$(readlink -f "$2" | sed 's/\/*$//')
if [ ! -d "$src" ]; then
	delimiter '!'
	echo "ОШИБКА: Источник '$src' не является каталогом!"
	delimiter '!'
	exit 1
fi
if [ ! -d "$dst" ]; then
	delimiter '!'
	echo "ОШИБКА: Приемник '$dst' не является каталогом!"
	delimiter '!'
	exit 1
fi

#Запускаем обход директорий:
export src dst arg_d arg_r arg_c
delimiter '-'
IFS=$'\n'
delete_all && copy_all
