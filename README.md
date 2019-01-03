TODO:
 - Consider how runKW can be modified to include multiple buckets by resolving ids. Is it desirable to have one interpreter for all buckets, or an interpreter for each bucket?
 - 'push 5 5 5' pushes with lifetime 5 and logs 'push 5 5 5' ... should there be 'too many args' complaints, or just silent truncation before logging?
 - A known problem:
     `$ cycle 1 2 3 4 5`
  succeeds, and is equivalent to
     `$ cycle`
  but logs
     `> cycle 1 2 3 4 5`
 - Error messages can be a bit lacking:
     `tweak 1 2 3`
  yields
     `error => invalid lifetime`
  Is the following more desirable?
     `error => invalid lifetime, 
     details => "2 3" is invalid`
