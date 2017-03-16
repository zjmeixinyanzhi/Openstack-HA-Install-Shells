#/bin/bash
for STYLE in 0 1 2 3 4 5 6 7; do
  for FG in 30 31 32 33 34 35 36 37; do
    for BG in 40 41 42 43 44 45 46 47; do
      CTRL="\033[${STYLE};${FG};${BG}m"
      echo -en "${CTRL}"
      echo -n "${STYLE};${FG};${BG}"
      echo -en "\033[0m"
    done
    echo
  done
  echo
done
# Reset
echo -e "\033[0m"


echo -e "\033[字背景颜色；文字颜色m字符串\033[0m"
echo -e "\033[41;36m something here \033[0m"
echo -e "\033[31m 红色字 \033[0m"
echo -e "\033[34m 黄色字 \033[0m" 
echo -e "\033[41;33m 红底黄字 \033[0m"
echo -e "\033[41;37m 红底白字 \033[0m" 
