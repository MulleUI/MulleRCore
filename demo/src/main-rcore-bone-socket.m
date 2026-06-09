/*******************************************************************************************
*
*   raylib [models] example - bone socket
*
*   Ported to MulleRCore: uses RCoreOSWindow for window/event management.
*   Input is read via UIInputState (pressedKeys) instead of raylib's IsKey* functions.
*
*   Original example by iP (@ipzaur), reviewed by Ramon Santamaria (@raysan5)
*   Licensed under zlib/libpng license.
*
********************************************************************************************/
#import "import-private.h"

#import "RCoreOSWindow.h"
#import "RCoreOSWindow+UIEvent.h"

#include "raylib.h"
#include "raymath.h"
#include "rcamera.h"

#define BONE_SOCKETS      3
#define BONE_SOCKET_HAT     0
#define BONE_SOCKET_HAND_R  1
#define BONE_SOCKET_HAND_L  2


struct DemoState
{
   Model            characterModel;
   Model            equipModel[BONE_SOCKETS];
   ModelAnimation   *modelAnimations;
   int              animsCount;
   unsigned int     animIndex;
   unsigned int     animCurrentFrame;
   int              boneSocketIndex[BONE_SOCKETS];
   BOOL             showEquip[3];
   unsigned short   angle;
   Camera           camera;
   NSUInteger       previousKeys[UIKeyStatesMaxKeys];
   NSUInteger       previousKeyCount;
   CGPoint          previousMouseLocation;
};

static struct DemoState   state;


static void   demoInit( void)
{
   state.camera.position   = (Vector3){ 5.0f, 5.0f, 5.0f };
   state.camera.target     = (Vector3){ 0.0f, 2.0f, 0.0f };
   state.camera.up         = (Vector3){ 0.0f, 1.0f, 0.0f };
   state.camera.fovy       = 45.0f;
   state.camera.projection = CAMERA_PERSPECTIVE;

   state.characterModel   = LoadModel( "resources/models/gltf/greenman.glb");
   state.equipModel[0]    = LoadModel( "resources/models/gltf/greenman_hat.glb");
   state.equipModel[1]    = LoadModel( "resources/models/gltf/greenman_sword.glb");
   state.equipModel[2]    = LoadModel( "resources/models/gltf/greenman_shield.glb");

   state.showEquip[0] = YES;
   state.showEquip[1] = YES;
   state.showEquip[2] = YES;

   state.modelAnimations = LoadModelAnimations( "resources/models/gltf/greenman.glb",
                                                &state.animsCount);
   state.boneSocketIndex[0] = -1;
   state.boneSocketIndex[1] = -1;
   state.boneSocketIndex[2] = -1;

   for( int i = 0; i < state.characterModel.skeleton.boneCount; i++)
   {
      if( TextIsEqual( state.characterModel.skeleton.bones[i].name, "socket_hat"))
         state.boneSocketIndex[BONE_SOCKET_HAT] = i;
      else if( TextIsEqual( state.characterModel.skeleton.bones[i].name, "socket_hand_R"))
         state.boneSocketIndex[BONE_SOCKET_HAND_R] = i;
      else if( TextIsEqual( state.characterModel.skeleton.bones[i].name, "socket_hand_L"))
         state.boneSocketIndex[BONE_SOCKET_HAND_L] = i;
   }
}


static void   demoFinalize( void)
{
   UnloadModelAnimations( state.modelAnimations, state.animsCount);
   UnloadModel( state.characterModel);
   for( int i = 0; i < BONE_SOCKETS; i++)
      UnloadModel( state.equipModel[i]);
}


static UIWindowDisplayBits   frameCallback( id <UIOSWindow> osWindow)
{
   RCoreOSWindow      *window = (RCoreOSWindow *) osWindow;
   struct UIInputState inputState;
   NSUInteger          keys[UIKeyStatesMaxKeys];
   NSUInteger          keyCount;

   // --- Update (using UIInputState from MulleRCore) ---

   inputState = [window inputState];
   keyCount   = [window pressedKeys:keys count:UIKeyStatesMaxKeys];

   // Camera update using UIInputState (replaces raylib's UpdateCamera)
   {
      CGPoint   mouseDelta;
      float     moveSpeed = 0.09f;
      float     rotSpeed  = 0.003f;

      mouseDelta.x = inputState.locationInWindow.x - state.previousMouseLocation.x;
      mouseDelta.y = inputState.locationInWindow.y - state.previousMouseLocation.y;
      state.previousMouseLocation = inputState.locationInWindow;

      // Mouse orbit
      CameraYaw( &state.camera, -mouseDelta.x * rotSpeed, true);
      CameraPitch( &state.camera, -mouseDelta.y * rotSpeed, true, true, false);

      // Keyboard orbit/move
      for( NSUInteger i = 0; i < keyCount; i++)
      {
         switch( keys[i])
         {
         case KEY_UP    : CameraPitch( &state.camera,  rotSpeed * 2.0f, true, true, false); break;
         case KEY_DOWN  : CameraPitch( &state.camera, -rotSpeed * 2.0f, true, true, false); break;
         case KEY_RIGHT : CameraYaw( &state.camera, -rotSpeed * 2.0f, true); break;
         case KEY_LEFT  : CameraYaw( &state.camera,  rotSpeed * 2.0f, true); break;
         case KEY_W     : CameraMoveForward( &state.camera,  moveSpeed, true); break;
         case KEY_S     : CameraMoveForward( &state.camera, -moveSpeed, true); break;
         case KEY_A     : CameraMoveRight( &state.camera, -moveSpeed, true); break;
         case KEY_D     : CameraMoveRight( &state.camera,  moveSpeed, true); break;
         }
      }

      // Scroll wheel zoom
      {
         CGFloat   wheel = [window consumeScrollWheelDelta];
         if( wheel != 0.0f)
            CameraMoveToTarget( &state.camera, -wheel);
      }
   }

   // Rotate character (F/H keys — held)
   for( NSUInteger i = 0; i < keyCount; i++)
   {
      if( keys[i] == KEY_F)
         state.angle = (state.angle + 1) % 360;
      else if( keys[i] == KEY_H)
         state.angle = (360 + state.angle - 1) % 360;
   }

   // Toggle actions (T/G/1/2/3) — detect newly pressed via diff
   for( NSUInteger i = 0; i < keyCount; i++)
   {
      NSUInteger   key;
      BOOL         wasDown;

      key     = keys[i];
      wasDown = NO;
      for( NSUInteger j = 0; j < state.previousKeyCount; j++)
      {
         if( state.previousKeys[j] == key)
         {
            wasDown = YES;
            break;
         }
      }
      if( ! wasDown)
      {
         switch( key)
         {
         case KEY_T     : state.animIndex = (state.animIndex + 1) % state.animsCount; break;
         case KEY_G     : state.animIndex = (state.animIndex + state.animsCount - 1) % state.animsCount; break;
         case KEY_ONE   : state.showEquip[BONE_SOCKET_HAT]    = ! state.showEquip[BONE_SOCKET_HAT]; break;
         case KEY_TWO   : state.showEquip[BONE_SOCKET_HAND_R] = ! state.showEquip[BONE_SOCKET_HAND_R]; break;
         case KEY_THREE : state.showEquip[BONE_SOCKET_HAND_L] = ! state.showEquip[BONE_SOCKET_HAND_L]; break;
         }
      }
   }

   memcpy( state.previousKeys, keys, keyCount * sizeof( NSUInteger));
   state.previousKeyCount = keyCount;

   // Advance animation
   {
      ModelAnimation   anim;

      anim = state.modelAnimations[state.animIndex];
      state.animCurrentFrame = (state.animCurrentFrame + 1) % anim.keyframeCount;
      UpdateModelAnimation( state.characterModel, anim, (float) state.animCurrentFrame);
   }

   // --- Draw ---

   ClearBackground( RAYWHITE);

   BeginMode3D( state.camera);
   {
      ModelAnimation   anim;
      Vector3          position = { 0.0f, 0.0f, 0.0f };

      anim = state.modelAnimations[state.animIndex];

      Quaternion  characterRotate = QuaternionFromAxisAngle(
                     (Vector3){ 0.0f, 1.0f, 0.0f }, state.angle * DEG2RAD);
      state.characterModel.transform = MatrixMultiply(
                     QuaternionToMatrix( characterRotate),
                     MatrixTranslate( position.x, position.y, position.z));
      UpdateModelAnimation( state.characterModel, anim, (float) state.animCurrentFrame);
      DrawMesh( state.characterModel.meshes[0],
                state.characterModel.materials[1],
                state.characterModel.transform);

      for( int i = 0; i < BONE_SOCKETS; i++)
      {
         if( ! state.showEquip[i])
            continue;

         Transform   *transform = &anim.keyframePoses[state.animCurrentFrame][state.boneSocketIndex[i]];
         Quaternion   inRotation  = state.characterModel.skeleton.bindPose[state.boneSocketIndex[i]].rotation;
         Quaternion   outRotation = transform->rotation;

         Quaternion   rotate = QuaternionMultiply( outRotation, QuaternionInvert( inRotation));
         Matrix       matrixTransform = QuaternionToMatrix( rotate);

         matrixTransform = MatrixMultiply( matrixTransform,
                              MatrixTranslate( transform->translation.x,
                                               transform->translation.y,
                                               transform->translation.z));
         matrixTransform = MatrixMultiply( matrixTransform, state.characterModel.transform);

         DrawMesh( state.equipModel[i].meshes[0],
                   state.equipModel[i].materials[1],
                   matrixTransform);
      }

      DrawGrid( 10, 1.0f);
   }
   EndMode3D();

   DrawText( "Use the T/G to switch animation", 10, 10, 20, GRAY);
   DrawText( "Use the F/H to rotate character left/right", 10, 35, 20, GRAY);
   DrawText( "Use the 1,2,3 to toggle shown of hat, sword and shield", 10, 60, 20, GRAY);

   {
      static double   lastTime;
      static int      fps;
      static int      frameCount;
      double          now;

      now = GetTime();
      frameCount++;
      if( now - lastTime >= 1.0)
      {
         fps        = frameCount;
         frameCount = 0;
         lastTime   = now;
      }
      DrawText( TextFormat( "FPS: %d", fps), 10, 85, 20, GREEN);
   }

   return( UIWindowDisplayNeedsAnimation);
}


int   main( int argc, char *argv[])
{
   RCoreOSWindow   *window;
   int              rval;

   window = [RCoreOSWindow windowWithFrame:CGRectMake( 0, 0, 800, 450)
                           titleUTF8String:"MulleRCore - Bone Socket"
                                 styleMask:UIWindowStyleResizable];
   if( ! window)
      return( 1);

   demoInit();

   [window os_setCursorCaptured:YES];
   [window setFrameCallback:frameCallback];
   [window setFrameRateHz:60.0];

   rval = UIApplicationRunWindow( window);

   demoFinalize();
   return( rval);
}
