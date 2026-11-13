function mdcp -a url
    if test -z "$url"
        echo "usage: mdcp <url>" >&2
        return 1
    end
  curl.md $url | cpy
  pst | mdfried
end
