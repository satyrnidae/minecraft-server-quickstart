# This is an example script for launching a minecraft JAR file.
# Feel free to modify this to your purposes.

echo 'Launching default Minecraft server jar...'
$JVM -server @user_jvm_args.txt -jar $SERVER_JAR "$@"
