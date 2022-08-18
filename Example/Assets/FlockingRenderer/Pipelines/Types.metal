typedef struct {
	float2 position;
	float2 velocity;
	float radius;
} Flocking;

typedef struct {
	float3 resolution;
	float time;
	int count;
	float flocking; //slider,0,1,1
	float zoneRadius; //slider,0,200,50
	float separation; //slider,0,1,0.375
	float alignment; //slider,0,1,0.375
	float cohesion; //slider,0,1,0.175
	float curl; //slider,0,1,0.1
	float curlScale; //slider,0,1,0.001
	float curlSpeed; //slider,0,1,0.1
	float damping; //slider,0,1,0.05
	float accelerationMax; //slider,0,10,5
	float velocityMax; //slider,0,10,5
	float radius; //slider,0,10,6
} FlockingUniforms;
