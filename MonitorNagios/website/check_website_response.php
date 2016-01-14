<?

# 	   
#   DESCRIPTION 
#		Check check_website_response.
#   NOTES 
#	Auteur  : Mohamed ACHBANI 
#	Date 	: 05-01-2016
#   SYNTAXE
#		php check_website_response.php "http://www.site.fr" 1000 3000
#	 	return : ('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3);  
######### 

if (!isset($argv[1]) or !isset($argv[2]) or !isset($argv[3])) { 
	echo "Usage: check_website_response <url>(http://) <warning> (milliseconds) <critical>(milliseconds) \n"; exit(3); 
}

$url 		= $argv[1];
$warning 	= $argv[2];
$critical	= $argv[3];

$url 		= preg_replace('/\s*/','',$url);
$warning 	= preg_replace('/\s*/','',$warning);
$critical	= preg_replace('/\s*/','',$critical);

function get_millis(){
  list($usec, $sec) = explode(' ', microtime());
  return (int) ((int) $sec * 1000 + ((float) $usec * 1000));
}

$time_start = get_millis();

$file_contents = file_get_contents($url);
if ($file_contents === false) {
	print "UNKNOWN : can not check address $url\n";
    exit(3); 
}

$time_end = get_millis();
$time = $time_end - $time_start;

if ($time < $warning) {
    print "OK : Response Time $time milliseconds  | 'Time'=$time, 'Time warning'=$warning, 'Time critical'=$critical";
    exit(0);
}
if ($time >= $warning && $time < $critical) {
    print "WARNING : Response Time $time milliseconds  | 'Time'=$time, 'Time warning'=$warning, 'Time critical'=$critical";
    exit(1);
}
if ($time >= $critical) {
    print "CRITICAL : Response Time $time milliseconds  | 'Time'=$time, 'Time warning'=$warning, 'Time critical'=$critical";
    exit(2);
}

?>