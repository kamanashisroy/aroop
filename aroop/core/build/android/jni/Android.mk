
LOCAL_PATH := $(call my-dir)
CONFIG_MK := $(LOCAL_PATH)/.config.mk
include $(CONFIG_MK)

include $(CLEAR_VARS)

LOCAL_LDLIBS := -llog
LOCAL_CFLAGS := -DAROOP_BASIC -DAROOP_ANDROID

LOCAL_MODULE    := ndk1
LOCAL_C_INCLUDES := $(CORE_PATH)/inc $(CORE_PATH)/platform/android/inc
LOCAL_SRC_FILES := $(CORE_PATH)/src/aroop_core.c $(CORE_PATH)/src/opp_factory_profiler.c $(CORE_PATH)/src/opp_list.c $(CORE_PATH)/src/opp_str2.c \
$(CORE_PATH)/src/aroop_txt.c $(CORE_PATH)/src/opp_hash.c $(CORE_PATH)/src/opp_queue.c $(CORE_PATH)/src/opp_thread_main.c \
$(CORE_PATH)/src/opp_any_obj.c $(CORE_PATH)/src/opp_hash_table.c $(CORE_PATH)/src/opp_rbtree_internal.c $(CORE_PATH)/src/opp_watchdog.c \
$(CORE_PATH)/src/opp_factory.c $(CORE_PATH)/src/opp_indexed_list.c $(CORE_PATH)/src/opp_salt.c 


include $(BUILD_SHARED_LIBRARY)
