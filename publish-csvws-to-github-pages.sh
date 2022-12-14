echo "--Publishing Output to GitHub Pages"

# Fail on errors (and other things)
set -euo pipefail

if [[ "$DEBUG" == true ]]
then
    set -x    
fi

git checkout gh-pages

# Get the uncommitted changes we've been making to this branch throughout this action.
if [[ -d "$RUNNER_TEMP/out" ]]
then
    cp -r "$RUNNER_TEMP/out" .
fi

# Pick up any file deletions stored in the stash
git stash pop || true

repo_name=${GITHUB_REPOSITORY#*/}    
username=${GITHUB_REPOSITORY_OWNER}
commit_id=${GITHUB_SHA}      
mapfile -t out_files < <(printf '%s\n' $(find out -type f -name '*'))
processed_out_files=$(printf "|||%s" "${out_files[@]}")

touch .nojekyll
touch index.html

cat > index.html <<EOL
<!doctype html>
<html>
    <head>
    </head>
    <body>
    <h3>CSV-Ws generated are as below. The latest commit id is ${commit_id}.</h3>
    <div id="files-container"></div>
    <script type="text/javascript">
        var html_str = "<ul>";
        var files = "${processed_out_files}".split('|||');
        files.shift()
        files.sort()
        files.forEach(function(file) {
        file = file.replace("./","")
        link = "https://${username}.github.io/${repo_name}/"+file
        html_str += "<li>"+"<a href='"+ link + "'>"+file+"</a></li>";
        });
        html_str += "</ul>";
        document.getElementById("files-container").innerHTML = html_str;
    </script>
    </body>
</html>
EOL

git add .nojekyll
git add index.html
git add out/
git commit -a -m "Updating outputs in GitHub Pages - $(date +'%d-%m-%Y at %H:%M:%S')"
git push --set-upstream origin gh-pages -f