import subprocess

secret_keys = [

]

is_ranked = True

if __name__ == '__main__':
    processes = []
    for key in secret_keys:
        processes.append(subprocess.Popen(
            ['python', 'run_bot.py', key, str(is_ranked)], stdout=subprocess.PIPE, stdin=subprocess.PIPE))

    input("Press a key to terminate")

    for process in processes:
        process.kill()

    exit(0)
