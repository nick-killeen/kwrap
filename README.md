TODO:
 - Consider how runKW can be modified to include multiple buckets by resolving ids. Is it desirable to have one interpreter for all buckets, or an interpreter for each bucket?
 - 'push 5 5 5' pushes with lifetime 5 and logs 'push 5 5 5' ... should there be 'too many args' complaints, or just silent truncation before logging?