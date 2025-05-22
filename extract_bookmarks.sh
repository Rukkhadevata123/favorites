#!/bin/bash
# 文件名: extract_bookmarks.sh
# 功能: 从浏览器导出的书签HTML文件中提取URL、分类和名称，并生成新的HTML文件

# 检查输入参数
if [ $# -ne 2 ]; then
    echo "用法: $0 输入文件 输出文件"
    exit 1
fi

INPUT_FILE=$1
OUTPUT_FILE=$2

# 统计原始文件中的链接数量
ORIGINAL_COUNT=$(grep -c '<DT><A HREF' "$INPUT_FILE")
echo "原始文件中的链接数量: $ORIGINAL_COUNT"

# 创建HTML头部，包含CSS样式
cat > "$OUTPUT_FILE" << 'EOL'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>我的收藏夹</title>
    <style>
        body {
            font-family: 'Microsoft YaHei', Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
            color: #333;
        }
        h1 {
            text-align: center;
            color: #2c3e50;
            margin-bottom: 30px;
        }
        .category {
            background-color: white;
            border-radius: 8px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            margin-bottom: 20px;
            padding: 15px;
        }
        .category h2 {
            margin-top: 0;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
            color: #3498db;
        }
        .bookmark-list {
            padding-left: 0;
        }
        .bookmark-list li {
            list-style-type: none;
            margin-bottom: 8px;
        }
        .bookmark-list a {
            color: #2980b9;
            text-decoration: none;
            display: block;
            padding: 6px 10px;
            border-radius: 4px;
            transition: background-color 0.2s;
        }
        .bookmark-list a:hover {
            background-color: #f0f7ff;
            color: #1a5276;
        }
        .subcategory {
            margin-left: 20px;
            margin-bottom: 15px;
        }
        .subcategory h3 {
            color: #16a085;
            margin-bottom: 10px;
        }
        .search-box {
            display: flex;
            justify-content: center;
            margin-bottom: 20px;
        }
        #search {
            padding: 8px 15px;
            width: 70%;
            max-width: 600px;
            border: 1px solid #ddd;
            border-radius: 4px;
            font-size: 16px;
        }
        @media (max-width: 768px) {
            body {
                padding: 10px;
            }
            .category {
                padding: 10px;
            }
        }
        /* 折叠功能 */
        .collapsible {
            cursor: pointer;
        }
        .collapsible:after {
            content: " 📑";
            font-size: 0.8em;
        }
        .active:after {
            content: " 📂";
        }
        .content {
            display: block;
            overflow: hidden;
        }
        .stats {
            text-align: center;
            font-size: 0.8em;
            color: #777;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <h1>我的收藏夹</h1>
    <div class="search-box">
        <input type="text" id="search" placeholder="搜索书签..." onkeyup="searchBookmarks()">
    </div>
EOL

# 创建临时文件来存储处理过程中的计数
TEMP_COUNT_FILE=$(mktemp)

# 提取并处理书签
awk -v temp_count_file="$TEMP_COUNT_FILE" '
BEGIN {
    print_line = 0;
    level = 0;
    category = "";
    last_category = "";
    link_count = 0;
}

/<DT><H3/ {
    if (match($0, />([^<]+)<\/H3>/, arr)) {
        category = arr[1];
        if (category != "收藏夹栏" && category != "未分类") {
            if (level > 0) {
                print "        </ul>\n    </div>\n</div>"
            }
            print "<div class=\"category\">\n    <h2 class=\"collapsible\">" category "</h2>\n    <div class=\"content\">\n        <ul class=\"bookmark-list\">"
            level = 1;
            last_category = category;
        }
    }
}

/<DT><A HREF/ {
    if (match($0, /HREF="([^"]+)"/, url) && match($0, /<A [^>]*>([^<]+)<\/A>/, title)) {
        if (last_category != "") {
            print "            <li><a href=\"" url[1] "\" target=\"_blank\">" title[1] "</a></li>"
            link_count++;
        }
    }
}

END {
    if (level > 0) {
        print "        </ul>\n    </div>\n</div>"
    }
    # 将链接计数写入临时文件
    print link_count > temp_count_file
}
' "$INPUT_FILE" >> "$OUTPUT_FILE"

# 读取临时文件中的链接计数
EXTRACTED_COUNT=$(cat "$TEMP_COUNT_FILE")
rm "$TEMP_COUNT_FILE"

# 添加统计信息
cat >> "$OUTPUT_FILE" << EOF
    <div class="stats">
        <p>共提取了 $EXTRACTED_COUNT 个书签链接</p>
    </div>
EOF

# 添加HTML尾部和JavaScript
cat >> "$OUTPUT_FILE" << 'EOL'
    <script>
        // 折叠功能
        document.addEventListener('DOMContentLoaded', function() {
            var coll = document.getElementsByClassName("collapsible");
            for (var i = 0; i < coll.length; i++) {
                coll[i].addEventListener("click", function() {
                    this.classList.toggle("active");
                    var content = this.nextElementSibling;
                    if (content.style.display === "none") {
                        content.style.display = "block";
                    } else {
                        content.style.display = "none";
                    }
                });
            }
        });

        // 搜索功能
        function searchBookmarks() {
            var input = document.getElementById("search");
            var filter = input.value.toUpperCase();
            var categories = document.getElementsByClassName("category");
            
            for (var i = 0; i < categories.length; i++) {
                var category = categories[i];
                var h2 = category.getElementsByTagName("h2")[0];
                var links = category.getElementsByTagName("a");
                var found = false;
                
                // 检查类别标题
                if (h2.textContent.toUpperCase().indexOf(filter) > -1) {
                    found = true;
                }
                
                // 检查书签
                for (var j = 0; j < links.length; j++) {
                    var link = links[j];
                    if (link.textContent.toUpperCase().indexOf(filter) > -1) {
                        found = true;
                        link.style.display = "";
                    } else {
                        link.style.display = "none";
                    }
                }
                
                if (found) {
                    category.style.display = "";
                    // 如果找到匹配项，确保内容可见
                    var content = h2.nextElementSibling;
                    if (content.style.display === "none") {
                        h2.classList.add("active");
                        content.style.display = "block";
                    }
                } else {
                    category.style.display = "none";
                }
            }
        }
    </script>
</body>
</html>
EOL

# 验证链接数量
OUTPUT_COUNT=$(grep -c '<a href="' "$OUTPUT_FILE")
echo "提取后的链接数量: $EXTRACTED_COUNT"
echo "输出文件中的链接数量: $OUTPUT_COUNT"

# 检查是否有链接丢失
if [ "$ORIGINAL_COUNT" -gt "$EXTRACTED_COUNT" ]; then
    echo "警告: 可能有 $(($ORIGINAL_COUNT - $EXTRACTED_COUNT)) 个链接未被提取!"
    echo "      (这可能是因为有些链接没有分类或在'收藏夹栏'/'未分类'中)"
elif [ "$ORIGINAL_COUNT" -lt "$EXTRACTED_COUNT" ]; then
    echo "警告: 提取的链接数量比原始文件多 $(($EXTRACTED_COUNT - $ORIGINAL_COUNT)) 个!"
    echo "      请检查脚本是否有错误。"
else
    echo "验证成功: 所有链接都已正确提取。"
fi

if [ "$OUTPUT_COUNT" -ne "$EXTRACTED_COUNT" ]; then
    echo "错误: 输出文件中的链接数量 ($OUTPUT_COUNT) 与提取的链接数量 ($EXTRACTED_COUNT) 不符!"
else
    echo "验证成功: 所有提取的链接都已正确写入输出文件。"
fi

echo "书签提取完成，已保存到 $OUTPUT_FILE"