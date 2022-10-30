class HDRadiCola:PortableStimpack{
	default{
		//$Category "Items/Hideous Destructor/Supplies"
		//$Title "Radi-Cola"
		//$Sprite "RDCLA0"

		scale 0.37;
		-hdpickup.droptranslation
		inventory.pickupmessage "Picked up a can of Radi-Cola.";
		inventory.icon "RDCLA0";
		hdpickup.bulk ENC_STIMPACK;
		tag "Radi-Cola";
		hdpickup.refid "rdc";
		+inventory.ishealth
		hdinjectormaker.injectortype "HDRadiColaDrinker";
	}
	states{
	spawn:
		RDCL A -1;
	}
}

class SpentRadiCola:HDActor{//code borrowed from HDFragGrenadeRoller
	vector3 keeprolling;
	
	default{//this should make empty cans kickable
	
	    -noextremedeath -floorclip +shootable +noblood +forcexybillboard
		+activatemcross -noteleport +noblockmonst +pushable
		+missile +bounceonactors +usebouncestate
		
		bouncetype "doom";
	    damagetype "none";
		bouncesound "misc/emptycan";
		bouncefactor 0.5;
		
		mass 10;
		scale 0.37;
		radius 4;
		height 4;
		alpha 1.0;
	}
	states{
	spawn:
		RDCL B 0 A_ChangeVelocity(velx*2+frandom(-1,1), vely*2+frandom(-1,1), velz+3, CVF_REPLACE);
		goto spawn2;
	spawn2:
		#### BBB 2{
			if(abs(vel.z-keeprolling.z)>10)A_StartSound("misc/emptycan",CHAN_BODY);
			else if(floorz>=pos.z)A_StartSound("misc/emptycan");
			keeprolling=vel;
			if(abs(vel.x)<0.4 && abs(vel.y)<0.4) setstatelabel("death");
		}loop;
	bounce:
		---- B 0{
			bmissile=false;
			vel*=0.9;
		}goto spawn2;
	death:
		---- B 2{
			if(abs(vel.z-keeprolling.z)>3){
				A_StartSound("misc/emptycan",CHAN_BODY);
				keeprolling=vel;
			}
			if(abs(vel.x)>0.4 || abs(vel.y)>0.4) setstatelabel("spawn");
		}wait;
	}
}


class HDRadiColaDrinker:HDWoundFixer{
	class<actor> injecttype;
	class<actor> spentinjecttype;
	class<inventory> inventorytype;
	string noerror;
	
	string injectoricon;
	property injectoricon:injectoricon;
	property injecttype:injecttype;
	class<inventory> injectortype;
	property injectortype:injectortype;
	
	property spentinjecttype:spentinjecttype;
	property inventorytype:inventorytype;
	property noerror:noerror;
	override inventory CreateTossable(int amt){
		HDWoundFixer.DropMeds(owner,0);
		return null;
	}
	override string,double getpickupsprite(){return "RDCLA0",1.;}
	override string gethelptext(){return WEPHELP_INJECTOR;}
	default{
		+hdweapon.dontdisarm
		hdradicoladrinker.injecttype "InjectRadiColaDummy";
		hdradicoladrinker.spentinjecttype "SpentRadiCola";
		hdradicoladrinker.inventorytype "HDRadiCola";
		hdradicoladrinker.noerror "No Radi-Cola left.";
		weapon.selectionorder 1003;
		HDRadiColaDrinker.injectoricon "RDCLA0";
		HDRadiColaDrinker.injectortype "HDRadiCola";
		
		// hdwoundfixer.injectoricon "RDCLA0";
		// hdwoundfixer.injectortype "HDRadiCola";
		tag "Radi-Cola";
	}
	states{
	spawn:
		TNT1 A 1;
		stop;
	select:
		TNT1 A 0{
			bool helptext=getcvar("hd_helptext");
			if(!countinv(invoker.inventorytype)){
				if(helptext)A_WeaponMessage(invoker.noerror);
				A_SelectWeapon("HDFist");
			}else if(helptext)A_WeaponMessage("\cd<<< \cjRADI-COLA \cd>>>\c-\n\nRadi-Cola helps provide a quick\nboost of energy and strength\nfor marines on the go.\n\n\Press altfire to share with a friend.\n\n\cgDO NOT MIX WITH STIMPACKS.\n\cgDRINK RESPONSIBLY.");
		}
		goto super::select;
	deselecthold:
		TNT1 A 1;
		TNT1 A 0 A_Refire("deselecthold");
		TNT1 A 0{
			A_SelectWeapon("HDFist");
			A_WeaponReady(WRF_NOFIRE);
		}goto nope;
	fire:
	hold:
		TNT1 A 1;
		TNT1 A 0{
			if(hdplayerpawn(self))hdplayerpawn(self).gunbraced=false;
			bool helptext=getcvar("hd_helptext");
			if(!countinv(invoker.inventorytype)){
				if(helptext)A_WeaponMessage(invoker.noerror);
				return resolvestate("deselecthold");
			}
			let blockinv=HDWoundFixer.CheckCovered(self,CHECKCOV_ONLYFULL);
			if(blockinv){
				if(helptext)A_WeaponMessage("Take off your "..blockinv.gettag().." first!",2);
				return resolvestate("nope");
			}
			if(pitch>-55){//bottoms up!
				A_MuzzleClimb(0,-8);
				A_Refire();
				return resolvestate(null);
			}
			return resolvestate("inject");
		}goto nope;
	inject:
		TNT1 A 1{
			A_TakeInjector(invoker.inventorytype);
			A_SetBlend("7a 3a 18",0.1,4);
			A_MuzzleClimb(0,2);
		
/*	if(hdplayerpawn(self))A_StartSound(hdplayerpawn(self).medsound,CHAN_VOICE);
			else A_StartSound("*usemeds",CHAN_VOICE);
*/

			A_StartSound("misc/radicola",CHAN_WEAPON);

			actor a=spawn(invoker.injecttype,pos,ALLOW_REPLACE);
			a.accuracy=40;a.target=self;
		}
		TNT1 AAAA 1 A_MuzzleClimb(0,-0.5);
		TNT1 A 6;
		TNT1 A 0{
			actor a=spawn(invoker.spentinjecttype,pos+(0,0,height-8),ALLOW_REPLACE);
			a.angle=angle;a.vel=vel;a.A_ChangeVelocity(3,1,2,CVF_RELATIVE);
			a.A_StartSound("weapons/grenopen",8);
		}
		goto drankedhold;
	altfire:
		TNT1 A 10;
		TNT1 A 0 A_Refire();
		goto nope;
	althold:
		TNT1 A 0{
			if(!countinv(invoker.inventorytype)){
				if(getcvar("hd_helptext"))A_WeaponMessage(invoker.noerror);
				A_Refire("deselecthold");
			}
		}
		TNT1 A 8{
			bool helptext=getcvar("hd_helptext");
			flinetracedata injectorline;
			linetrace(
				angle,42,pitch,
				offsetz:height-12,
				data:injectorline
			);
			let c=HDPlayerPawn(injectorline.hitactor);
			if(!c){
				let ccc=HDHumanoid(injectorline.hitactor);
				if(
					ccc
					&&invoker.getclassname()=="HDRadiColaDrinker"
				){
					if(
						ccc.stunned<100
						||ccc.health<10
					){
						if(helptext)A_WeaponMessage("They don't want any.",2);
						return resolvestate("nope");
					}
					A_TakeInjector(invoker.inventorytype);
					ccc.A_StartSound(ccc.painsound,CHAN_VOICE);
					ccc.stunned=max(0,ccc.stunned>>1);
					if(!countinv(invoker.inventorytype))return resolvestate("deselecthold");
					return resolvestate("dranked");
				}
				if(helptext)A_WeaponMessage("Nothing to be done here.\n\nHave a drink? (press fire)",2);
				return resolvestate("nope");
			}
			let blockinv=HDWoundFixer.CheckCovered(self,CHECKCOV_ONLYFULL);
			if(blockinv){
				if(helptext)A_WeaponMessage("You'll need them to take off their "..blockinv.gettag().."...");
				return resolvestate("nope");
			}
			if(c.countinv("IsMoving")>4){
				bool chelptext=c.getcvar("hd_helptext");
				if(c.countinv("HDStim")){
					if(chelptext)c.A_Print(string.format("Run away!!!\n\n%s is trying to overdose you\n\n(and possibly bugger you)...",player.getusername()));
					if(helptext)A_WeaponMessage("They seem kinda wired already...");
				}else{
					if(chelptext)c.A_Print(string.format("Hey, slow down!\n\n%s only wants to\n\ngive you some Radi-Cola...",player.getusername()));
					if(helptext)A_WeaponMessage("You'll need them to stay still...");
				}
				return resolvestate("nope");
			}
			if(
				//because poisoning people should count as friendly fire!
				(teamplay || !deathmatch)&&
				(
					(
						invoker.injecttype=="InjectRadiColaDummy"
						&& c.countinv("HDStim")
					)||
					(
						invoker.injecttype=="InjectZerkDummy"
						&& c.countinv("HDZerk")>HDZerk.HDZERK_COOLOFF
					)
				)
			){
				if(c.getcvar("hd_helptext"))c.A_Print(string.format("Run away!!!\n\n%s is trying to overdose you\n\n(and possibly bugger you)...",player.getusername()));
				if(getcvar("hd_helptext"))A_WeaponMessage("They seem kinda wired already...");
				return resolvestate("nope");
			}
			//and now...
			A_TakeInjector(invoker.inventorytype);
			c.A_StartSound(hdplayerpawn(c).medsound,CHAN_VOICE);
			c.A_SetBlend("7a 3a 18",0.1,4);
			actor a=spawn(invoker.injecttype,c.pos,ALLOW_REPLACE);
			a.accuracy=40;a.target=c;
			if(!countinv(invoker.inventorytype))return resolvestate("deselecthold");
			return resolvestate("dranked");
		}
	dranked:
		TNT1 A 0{
			actor a=spawn(invoker.spentinjecttype,pos+(0,0,height-8),ALLOW_REPLACE);
			a.angle=angle;a.vel=vel;a.A_ChangeVelocity(-2,1,4,CVF_RELATIVE);
			A_StartSound("weapons/grenopen",CHAN_VOICE);
		}
	drankedhold:
		TNT1 A 1 A_ClearRefire();
		TNT1 A 0 A_JumpIf(pressingfire(),"drankedhold");
		TNT1 A 10 A_SelectWeapon("HDFist");
		TNT1 A 1 A_WeaponReady(WRF_NOFIRE);
		goto readyend;
	}
}

class InjectRadiColaDummy:IdleDummy{
	hdplayerpawn tg;
	states{
	spawn:
		TNT1 A 6 nodelay{
			tg=HDPlayerPawn(target);
			if(!tg||tg.bkilled){destroy();return;}
			if(tg.countinv("HDZerk")>HDZerk.HDZERK_COOLOFF)tg.aggravateddamage+=int(ceil(accuracy*0.01*random(0,1)));
		}
		TNT1 A 1{
			if(!target||target.bkilled){destroy();return;}
			HDF.Give(target,"HDStim",HDStim.HDSTIM_DOSE*0.2);
		}stop;
	}
}

class RadiCola_Spawner : EventHandler
{

override void CheckReplacement(ReplaceEvent e) {
	switch (e.Replacee.GetClassName()) {

	case 'BlueFrag' 			: if (!random(0, 5)) {e.Replacement = "HDRadiCola";} break;

  case 'HelmFrag' 			: if (!random(0, 7)) {e.Replacement = "HDRadiCola";} break;

  case 'DecoPusher' 			: if (!random(0, 9)) {e.Replacement = "SpentRadiCola";} break;

		}

	e.IsFinal = false;
	}
}

