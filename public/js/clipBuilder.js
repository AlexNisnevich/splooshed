var Clips = {};
var index = 0;
Clips[0] = new Howl({
  urls: ['songs/k1.wav'],
	onend: function(){
		fuckK();
	}
});


Clips[1] = new Howl({
	urls: ['songs/k2.wav'],

	onend: function(){
		fuckK();
	}
});

Clips[2] = new Howl({
	urls: ['songs/k3.wav']

});

Clips[3] = new Howl({

	urls: ['songs/k4.wav'],
	onend: function(){
		fuckK();
	}
});

var playK = function(){
	Clips[index].stop();
	index += 3;
	index = index % 4;
	Clips[index].play();


};

var fuckK = function(){
	
	//document.body.style.backgroundColor = "blue";

};
