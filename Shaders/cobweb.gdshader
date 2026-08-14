shader_type canvas_item;

const vec3 diffuse = vec3( .2, 1.0, 0.5 );
const vec3 eps = vec3( .002, 0.5, 0. );
const int iter = 130;
const float sq = 1.0;

float c( vec3 p )
{
	vec3 q = abs(mod(p+vec3(cos(p.z*0.5), cos(p.x*0.5), cos(p.y*0.5)),2.0)-1.0);
	float a = q.x + q.y + q.z - min(min(q.x, q.y), q.z) - max(max(q.x, q.y), q.z);
	q = vec3(p.x+p.y, p.y+p.z, p.z+p.x)*sq;
	q = abs(mod(q,2.0)-1.0);
	float b = q.x + q.y + q.z - min(min(q.x, q.y), q.z) - max(max(q.x, q.y), q.z);
	return min(a,b);
}

vec3 n( vec3 p )
{
	float o = c( p );
	return normalize( o - vec3( c( p - eps ), c( p - eps.zxy ), c( p - eps.yzx ) ) );
}


void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec2 p = UV.xy;
	vec3 o = vec3( 0., 0., TIME*0.5 );
	vec3 b = vec3( 0., 1., 0. );
	vec3 d = vec3( p, 1. ) / 32.;
	vec3 t = vec3( .5 );
	vec3 a;
	
	for( int i = 0; i < iter; ++i )
	{
		float h = c( b + o );
		//if( h < 0. )
		//	break;
		b += h * 10.0 * d;
		t += h;
	}
	t /= float( iter );
	a = n( b + o );
	float x = dot( a, t );
	t = ( t + pow( x, 4. ) ) * ( 1. - t * .01 ) * diffuse;
	t *= b.z *0.125 ; 
	

	vec2 vig = p*0.43;
	float vig_amount = 1.0- length(vig);
	vec4 color = vec4( t*2.0, 1. )* vig_amount;
	//vec4 tc = texture(TEXTURE, UV);
	COLOR = color;
	
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
