import sys
from subprocess import PIPE, Popen
from threading  import Thread
import os
import resource
import logging
import time

def RunProcess(cmds,callback=None,env = None,bufsize=2):
  """Runs a process, calls callback with stdout/stderr during execution, and returns the exit code when finished"""
  try:
      from Queue import Queue, Empty
  except ImportError:
      from queue import Queue, Empty  # python 3.x

  ON_POSIX = 'posix' in sys.builtin_module_names

  def enqueue_input(myin, queue):
    print("enqueue_input")
    return
  
  def enqueue_output(out, queue):
    if out.closed ==  False:
      for line in iter(out.readline, b''):
          queue.put(line)
    out.close()
      
  def setlimits():
      # Set maximum CPU time to 1 second in child process, after fork() but before exec()
      logging.debug("Setting resource limit in child (pid %d)" % os.getpid());
      resource.setrlimit(resource.RLIMIT_STACK, (resource.RLIM_INFINITY, resource.RLIM_INFINITY))

  p = Popen(cmds, universal_newlines=True, stdout=PIPE, stdin=PIPE, stderr=PIPE,bufsize=bufsize, close_fds=ON_POSIX, env=env, preexec_fn=setlimits)
  p.stdin.write("y\n") # Answer yes to overwrite question
  
  q = Queue()
  
  stdoutThread = Thread(target=enqueue_output, args=(p.stdout, q))
  stdoutThread.daemon = True;  
  stdoutThread.start()
  
  stderrThread = Thread(target=enqueue_output, args=(p.stderr, q))
  stderrThread.daemon = True;  
  stderrThread.start()
  
  #http://stackoverflow.com/questions/156360/get-all-items-from-thread-queue
  # read line without blocking
  for i in range(2):
    """ Somehow sometimes stuff is still in que, do it twice """
    while True:
      try:
        line = q.get(timeout=.1)
        if(callback != None):
          callback(line)
        if(p.poll() != None):
          break;
      except Empty:
          if(stdoutThread.isAlive() == False):
            break;

    

  return p.wait()  
