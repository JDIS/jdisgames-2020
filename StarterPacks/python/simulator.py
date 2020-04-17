import subprocess

secret_keys = [
    
]

if __name__ == '__main__':
    processes = []
    for key in secret_keys:
        processes.append(subprocess.Popen(['python', 'run_bot.py', key], stdout=subprocess.PIPE, stdin=subprocess.PIPE))

    input("Press a key to terminate")

    for process in processes:
        process.kill()

    exit(0)
