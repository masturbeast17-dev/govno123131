#define TE_BEAMPOINTS 0 // Луч между двумя точками (Beam effect between two points)
stock CREATE_BEAMPOINTS(Float:fStartOrigin[3], Float:fEndOrigin[3], pSprite, iStartFrame = 0, iFrameRate = 0, iLife, iWidth, iAmplitude = 0, iRed, iGreen, iBlue, iBrightness, iScrollSpeed = 0, iReliable = 0)
{
	message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMPOINTS);
	engfunc(EngFunc_WriteCoord, fStartOrigin[0]);
	engfunc(EngFunc_WriteCoord, fStartOrigin[1]);
	engfunc(EngFunc_WriteCoord, fStartOrigin[2]);
	engfunc(EngFunc_WriteCoord, fEndOrigin[0]);
	engfunc(EngFunc_WriteCoord, fEndOrigin[1]);
	engfunc(EngFunc_WriteCoord, fEndOrigin[2]);
	write_short(pSprite); // Индекс спрайта из прекеша (index of precached sprite)
	write_byte(iStartFrame);
	write_byte(iFrameRate); // 0.1's
	write_byte(iLife); // 0.1's
	write_byte(iWidth);
	write_byte(iAmplitude); // 0.01's
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iBrightness);
	write_byte(iScrollSpeed); // 0.1's
	message_end();
}

#define TE_BEAMENTPOINT 1 // Луч между точкой и объектом (Beam effect between point and entity)
stock CREATE_BEAMENTPOINT(iEntity, Float:fOrigin[3], pSprite, iStartFrame = 0, iFrameRate = 0, iLife, iWidth, iAmplitude = 0, iRed, iGreen, iBlue, iBrightness, iScrollSpeed = 0, iReliable = 0)
{
	message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMENTPOINT);
	write_short(iEntity);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	write_short(pSprite); // Индекс спрайта из прекеша (index of precached sprite)
	write_byte(iStartFrame);
	write_byte(iFrameRate); // 0.1's
	write_byte(iLife); // 0.1's
	write_byte(iWidth);
	write_byte(iAmplitude); // 0.01's
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iBrightness);
	write_byte(iScrollSpeed); // 0.1's
	message_end();
}

#define TE_GUNSHOT 2 // Частицы и звук рикошета (Particle effect plus ricochet sound)
stock CREATE_BEAMENTPOINT(Float:fOrigin[3], iReliable = 0)
{
	engfunc(EngFunc_MessageBegin, iReliable ? MSG_PAS_R : MSG_PAS, SVC_TEMPENTITY, fOrigin, 0);
	write_byte(TE_GUNSHOT);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	message_end();
}

#define TE_EXPLOSION 3 // Взрыв с подсветкой, звуком и частицами (Additive sprite, 2 dynamic lights, flickering particles, explosion sound, move vertically 8 pps)

#define TE_EXPLFLAG_NONE 0 // Все Флаги по умолчанию (All flags clear makes default Half-Life explosion)
#define TE_EXPLFLAG_NOADDITIVE 1 // Отключить прозрачность спрайта (Sprite will be drawn opaque (ensure that the sprite you send is a non-additive sprite))
#define TE_EXPLFLAG_NODLIGHTS 2 // Не создавать подсветку вокруг взрыва (Do not render dynamic lights)
#define TE_EXPLFLAG_NOSOUND 4 // Не воспроизводить звук взрыва (Do not play client explosion sound)
#define TE_EXPLFLAG_NOPARTICLES 8 // Не создавать частицы после взрыва (Do not draw particles)

stock CREATE_EXPLOSION(Float:fOrigin[3], pSprite, iScale, iFrameRate = 0, iFlags = 0, iReliable = 0)
{
	message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	write_short(pSprite); // Индекс спрайта из прекеша (index of precached sprite)
	write_byte(iScale);
	write_byte(iFrameRate); // 0.1's
	write_byte(iFlags);
	message_end();
}

#define TE_TAREXPLOSION 4 // Звук взрыва и разлетающихся частиц (Quake1 "tarbaby" explosion with sound)
stock CREATE_TAREXPLOSION(Float:fOrigin[3], iReliable = 0)
{
	engfunc(EngFunc_MessageBegin, iReliable ? MSG_PAS_R : MSG_PAS, SVC_TEMPENTITY, fOrigin, 0);
	write_byte(TE_TAREXPLOSION);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	message_end();
}

#define TE_SMOKE 5 // Прозрачный спрайт, перемещающийся вертикально вверх, что-то наподобие клубов дыма (Alphablend sprite, move vertically 30 pps)
stock CREATE_SMOKE(Float:fOrigin[3], pSprite, iScale, iFrameRate = 0, iReliable = 0)
{
	message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_SMOKE);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	write_short(pSprite); // Индекс спрайта из прекеша (index of precached sprite)
	write_byte(iScale);
	write_byte(iFrameRate); // 0.1's
	message_end();
}

#define TE_TRACER 6 // Эффект трассирующего снаряда от точки до точки (Tracer effect from point to point)
stock CREATE_TRACER(Float:fStartOrigin[3], Float:fEndOrigin[3], iReliable = 0)
{
	message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_TRACER);
	engfunc(EngFunc_WriteCoord, fStartOrigin[0]);
	engfunc(EngFunc_WriteCoord, fStartOrigin[1]);
	engfunc(EngFunc_WriteCoord, fStartOrigin[2]);
	engfunc(EngFunc_WriteCoord, fEndOrigin[0]);
	engfunc(EngFunc_WriteCoord, fEndOrigin[1]);
	engfunc(EngFunc_WriteCoord, fEndOrigin[2]);
	message_end();
}

#define TE_LIGHTNING 7 // Тоже самое что TE_BEAMPOINTS, только с упрощенными параметрами (TE_BEAMPOINTS with simplified parameters)
stock CREATE_LIGHTNING(Float:fStartOrigin[3], Float:fEndOrigin[3], iLife, iWidth, iAmplitude = 0, pSprite, iReliable = 0)
{
	message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_LIGHTNING);
	engfunc(EngFunc_WriteCoord, fStartOrigin[0]);
	engfunc(EngFunc_WriteCoord, fStartOrigin[1]);
	engfunc(EngFunc_WriteCoord, fStartOrigin[2]);
	engfunc(EngFunc_WriteCoord, fEndOrigin[0]);
	engfunc(EngFunc_WriteCoord, fEndOrigin[1]);
	engfunc(EngFunc_WriteCoord, fEndOrigin[2]);
	write_byte(iLife); // 0.1's
	write_byte(iWidth);
	write_byte(iAmplitude); // 0.01's
	write_short(pSprite); // Индекс спрайта из прекеша (index of precached sprite)
	message_end();
}

#define TE_BEAMENTS 8 // Луч между двумя объектами (Beam effect between two entity)
stock CREATE_BEAMENTS(iEntityStart, iEntityEnd, pSprite, iStartFrame = 0, iFrameRate = 0, iLife, iWidth, iAmplitude = 0, iRed, iGreen, iBlue, iBrightness, iScrollSpeed = 0, iReliable = 0)
{
	message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMENTS);
	write_short(iEntityStart);
	write_short(iEntityEnd);
	write_short(pSprite); // Индекс спрайта из прекеша (index of precached sprite)
	write_short(iStartFrame);
	write_short(iFrameRate); // 0.1's
	write_byte(iLife); // 0.1's
	write_byte(iWidth);
	write_byte(iAmplitude); // 0.01's
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iBrightness);
	write_byte(iScrollSpeed); // 0.1's
	message_end();
}

#define TE_SPARKS 9 // Эффект замыкания или попадания пули в металл, искры одним словом (8 random tracers with gravity, ricochet sprite)
stock CREATE_SPARKS(Float:fOrigin[3], iReliable = 0)
{
	engfunc(EngFunc_MessageBegin, iReliable ? MSG_PVS_R : MSG_PVS, SVC_TEMPENTITY, fOrigin, 0);
	write_byte(TE_SPARKS);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	message_end();
}

#define TE_LAVASPLASH 10 // Эффект брызг крови или что-то вроде этого, в общем много красных частиц (Quake1 lava splash)
stock CREATE_LAVASPLASH(Float:fOrigin[3], iReliable = 0)
{
	message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_LAVASPLASH);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	message_end();
}

#define TE_TELEPORT 11 // Эффект телепортации, игрока или объекта (Quake1 teleport splash)
stock CREATE_TELEPORT(Float:fOrigin[3], iReliable = 0)
{
	engfunc(EngFunc_MessageBegin, iReliable ? MSG_PVS_R : MSG_PVS, SVC_TEMPENTITY, fOrigin, 0);
	write_byte(TE_TELEPORT);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	message_end();
}

#define TE_EXPLOSION2 12 // Тоже самое что TE_TAREXPLOSION, только тут можно выставлять цвет частиц (Quake1 colormaped (base palette) particle explosion with sound)
stock CREATE_EXPLOSION2(Float:fOrigin[3], iStartColor = 0, iNumColors = 255, iReliable = 0)
{
	engfunc(EngFunc_MessageBegin, iReliable ? MSG_PAS_R : MSG_PAS, SVC_TEMPENTITY, fOrigin, 0);
	write_byte(TE_EXPLOSION2);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	write_byte(min(iStartColor, 255));
	write_byte(min(iNumColors, 255));
	message_end();
}

#define TE_BSPDECAL 13 // Рисует декали из файла .BSP, как я понял, может рисовать декали из карты которая сейчас запущена (Decal from the .BSP file)
stock CREATE_BSPDECAL(Float:fOrigin[3], pDecal, iEntity = 0, pModel = 0, iReliable = 0)
{
	message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BSPDECAL);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	write_short(pDecal); // Индекс декали из прекеша (index of precached decal)
	write_short(iEntity);
	if(iEntity) write_short(pModel); // Индекс модели объекта, если объект не равен нулю [то есть объект не карта] (index of model of above entity, only included if previous short is non-zero [not the world])
	message_end();
}

#define TE_IMPLOSION 14 // Частицы движущиеся к центру координат, в общем появляется круг из частиц и эти частицы движутся в центр (Tracers moving toward a point)
stock CREATE_IMPLOSION(Float:fOrigin[3], iRadius, iCount, iLife, iReliable = 0)
{
	message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_IMPLOSION);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	write_byte(iRadius);
	write_byte(iCount);
	write_byte(iLife); // 0.1's
	message_end();
}

#define TE_SPRITETRAIL 15 // Создаёт спрайты которые могут сталкиваться с объектами, имеют гравитацию и физику (Line of moving glow sprites with gravity, fadeout, and collisions)
stock CREATE_SPRITETRAIL(Float:fStartOrigin[3], Float:fEndOrigin[3], pSprite, iCount, iLife, iScale, iVelocityAlongVector, iRandomVelocity, iReliable = 0)
{
	message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_SPRITETRAIL);
	engfunc(EngFunc_WriteCoord, fStartOrigin[0]);
	engfunc(EngFunc_WriteCoord, fStartOrigin[1]);
	engfunc(EngFunc_WriteCoord, fStartOrigin[2]);
	engfunc(EngFunc_WriteCoord, fEndOrigin[0]);
	engfunc(EngFunc_WriteCoord, fEndOrigin[1]);
	engfunc(EngFunc_WriteCoord, fEndOrigin[2]);
	write_short(pSprite); // Индекс спрайта из прекеша (index of precached sprite)
	write_byte(iCount);
	write_byte(iLife); // 0.1's
	write_byte(iScale);
	write_byte(iVelocityAlongVector); // 10's
	write_byte(iRandomVelocity); // 10's
	message_end(); 
}

#define TE_BEAM 16 // Устаревший (obsolete)

#define TE_SPRITE 17 // Показ любого прозрачного спрайта, проигрывает 1 цикл всех кадров (Additive sprite, plays 1 cycle)
stock CREATE_SPRITE(Float:fOrigin[3], pSptite, iWidth, iBrightness, iReliable = 0)
{
	engfunc(EngFunc_MessageBegin, iReliable ? MSG_PVS_R : MSG_PVS, SVC_TEMPENTITY, fOrigin, 0);
	write_byte(TE_SPRITE);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	write_short(pSptite); // Индекс спрайта из прекеша (index of precached sprite)
	write_byte(iWidth);
	write_byte(iBrightness);
	message_end();
}

#define TE_BEAMSPRITE 18 // Луч между двумя точками со спрайтом на конце (A beam with a sprite at the end)
stock CREATE_BEAMSPRITE(Float:fStartOrigin[3], Float:fEndOrigin[3], pSpriteBeam, pSpriteEnd, iReliable = 0)
{
	message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMSPRITE);
	engfunc(EngFunc_WriteCoord, fStartOrigin[0]);
	engfunc(EngFunc_WriteCoord, fStartOrigin[1]);
	engfunc(EngFunc_WriteCoord, fStartOrigin[2]);
	engfunc(EngFunc_WriteCoord, fEndOrigin[0]);
	engfunc(EngFunc_WriteCoord, fEndOrigin[1]);
	engfunc(EngFunc_WriteCoord, fEndOrigin[2]);
	write_short(pSpriteBeam); // Индекс спрайта из прекеша (index of precached sprite)
	write_short(pSpriteEnd); // Индекс спрайта из прекеша (index of precached sprite)
	message_end(); 
}

#define TE_BEAMTORUS 19 // Кольцо расширяющиеся до радиуса указанного в параметрах (Screen aligned beam ring, expands to max radius over lifetime)
stock CREATE_BEAMTORUS(Float:fOrigin[3], iRadius, pSprite, iStartFrame = 0, iFrameRate = 0, iLife, iWidth, iAmplitude = 0, iRed, iGreen, iBlue, iBrightness, iScrollSpeed = 0, iReliable = 0)
{
	message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMTORUS);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2] + 16.0 + iRadius * 2);
	write_short(pSprite); // Индекс спрайта из прекеша (index of precached sprite)
	write_byte(iStartFrame);
	write_byte(iFrameRate); // 0.1's
	write_byte(iLife); // 0.1's
	write_byte(iWidth);
	write_byte(iAmplitude); // 0.01's
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iBrightness);
	write_byte(iScrollSpeed); // 0.1's
	message_end();
}

#define TE_BEAMDISK 20 // Диск расширяющиеся до радиуса указанного в параметрах (Disk that expands to max radius over lifetime)
stock CREATE_BEAMDISK(Float:fOrigin[3], iRadius, pSprite, iStartFrame = 0, iFrameRate = 0, iLife, iWidth, iAmplitude = 0, iRed, iGreen, iBlue, iBrightness, iScrollSpeed = 0, iReliable = 0)
{
	message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMDISK);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2] + 16.0 + iRadius * 2);
	write_short(pSprite); // Индекс спрайта из прекеша (index of precached sprite)
	write_byte(iStartFrame);
	write_byte(iFrameRate); // 0.1's
	write_byte(iLife); // 0.1's
	write_byte(iWidth);
	write_byte(iAmplitude); // 0.01's
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iBrightness);
	write_byte(iScrollSpeed); // 0.1's
	message_end();
}

#define TE_BEAMCYLINDER 21 // Цилиндр расширяющиеся до радиуса указанного в параметрах (Cylinder that expands to max radius over lifetime)
stock CREATE_BEAMCYLINDER(Float:fOrigin[3], iRadius, pSprite, iStartFrame = 0, iFrameRate = 0, iLife, iWidth, iAmplitude = 0, iRed, iGreen, iBlue, iBrightness, iScrollSpeed = 0, iReliable = 0)
{
	message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMCYLINDER);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2] + 16.0 + iRadius * 2);
	write_short(pSprite); // Индекс спрайта из прекеша (index of precached sprite)
	write_byte(iStartFrame);
	write_byte(iFrameRate); // 0.1's
	write_byte(iLife); // 0.1's
	write_byte(iWidth);
	write_byte(iAmplitude); // 0.01's
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iBrightness);
	write_byte(iScrollSpeed); // 0.1's
	message_end();
}

#define TE_BEAMFOLLOW 22 // Линия исходящая от объекта, пока объект движется (Create a line of decaying beam segments until entity stops moving)
stock CREATE_BEAMFOLLOW(iEntity, pSptite, iLife, iWidth, iRed, iGreen, iBlue, iBrightness, iReliable = 0)
{
	message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(iEntity);
	write_short(pSptite);
	write_byte(iLife); // 0.1's
	write_byte(iWidth);
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iBrightness);
	message_end();
}

#define TE_GLOWSPRITE 23 // Светящийся спрайт, не знаю что это значит, пробуйте (Creates a glowing sprite)
stock CREATE_GLOWSPRITE(Float:fOrigin[3], pSptite, iScale, iSize, iBrightness, iReliable = 0)
{
	message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_GLOWSPRITE);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	write_short(pSptite); // Индекс спрайта из прекеша (index of precached sprite)
	write_byte(iScale);
	write_byte(iSize);
	write_byte(iBrightness);
	message_end();
}

#define TE_BEAMRING 24 // Кольцо в центре первого объекта, расширяющиеся до радиуса на котором находится второй объект, когда второй объект приближается к первому, кольцо сужается (Connect a beam ring to two entities)
stock CREATE_BEAMRING(iStartEntity, iEndEntity, pSprite, iStartFrame = 0, iFrameRate = 0, iLife, iWidth, iAmplitude = 0, iRed, iGreen, iBlue, iBrightness, iScrollSpeed = 0, iReliable = 0)
{
	message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMRING);
	write_short(iStartEntity);
	write_short(iEndEntity);
	write_short(pSprite); // Индекс спрайта из прекеша (index of precached sprite)
	write_byte(iStartFrame);
	write_byte(iFrameRate); // 0.1's
	write_byte(iLife); // 0.1's
	write_byte(iWidth);
	write_byte(iAmplitude); // 0.01's
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iBrightness);
	write_byte(iScrollSpeed); // 0.1's
	message_end();
}

#define TE_STREAK_SPLASH 25 // Частицы разлетаются в разные стороны (Oriented shower of tracers)
stock CREATE_BEAMRING(Float:fOrigin[3], Float:fVector[3] = {-1.0, 1.0, 0.0}, iColor, iCount, iSpeed, iRandomVelocity, iReliable = 0)
{
	engfunc(EngFunc_MessageBegin, iReliable ? MSG_PVS_R : MSG_PVS, SVC_TEMPENTITY, fOrigin, 0);
	write_byte(TE_STREAK_SPLASH);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	engfunc(EngFunc_WriteCoord, fVector[0]);
	engfunc(EngFunc_WriteCoord, fVector[1]);
	engfunc(EngFunc_WriteCoord, fVector[2]);
	write_byte(min(iColor, 255));
	write_short(iCount);
	write_short(iSpeed);
	write_short(iRandomVelocity);
	message_end();
}

#define TE_DLIGHT 27 // Создаёт динамичный свет (Dynamic light, effect world, minor entity effect)
stock CREATE_DLIGHT(Float:fOrigin[3], iRadius, iRed, iGreen, iBlue, iBrightness, iLife, iDecayRate = 0, iReliable = 0)
{
	message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_DLIGHT);
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	write_byte(iRadius);
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iBrightness);
	write_byte(iLife); // 0.1's
	write_byte(iDecayRate);
	message_end();
}

#define TE_ELIGHT 28 // Создаёт динамичный свет для объекта, не влияет на карту и другие объекты (Point entity light, no world effect)
stock CREATE_ELIGHT(iEntity, Float:fOrigin[3], iRadius, iRed, iGreen, iBlue, iBrightness, iLife, iDecayRate = 0, iReliable = 0)
{
	message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_ELIGHT);
	write_short(iEntity)
	engfunc(EngFunc_WriteCoord, fOrigin[0]);
	engfunc(EngFunc_WriteCoord, fOrigin[1]);
	engfunc(EngFunc_WriteCoord, fOrigin[2]);
	write_coord(iRadius);
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iBrightness);
	write_byte(iLife); // 0.1's
	write_coord(iDecayRate);
	message_end();
}

#define TE_LINE 30
stock CREATE_LINE(Float:fStartOrigin[3], Float:fEndOrigin[3], iLife, iRed, iGreen, iBlue, iReliable = 0)
{
	message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_LINE);
	engfunc(EngFunc_WriteCoord, fStartOrigin[0]);
	engfunc(EngFunc_WriteCoord, fStartOrigin[1]);
	engfunc(EngFunc_WriteCoord, fStartOrigin[2]);
	engfunc(EngFunc_WriteCoord, fEndOrigin[0]);
	engfunc(EngFunc_WriteCoord, fEndOrigin[1]);
	engfunc(EngFunc_WriteCoord, fEndOrigin[2]);
	write_short(iLife); // 0.1's
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	message_end();
}