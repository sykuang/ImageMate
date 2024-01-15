<script setup lang="ts">
import { ref } from 'vue';
window.electronAPI.sendMessage('Main Window Starting!');
const images = ref();
const imgSrc = ref();
images.value = [];
window.electronAPI.onOpenFile((img) => {
  window.electronAPI.sendMessage('Got Image');
  // images.value.push({
  // itemImageSrc: img.itemImageSrc,
  // thumbnailImageSrc: img.itemImageSrc,
  // alt: img.alt,
  // title: img.title
  // });
  imgSrc.value = img.itemImageSrc;
});
const responsiveOptions = [
  {
    breakpoint: '1300px',
    numVisible: 4
  },
  {
    breakpoint: '575px',
    numVisible: 1
  }
];
const positionOptions = ref([
  {
    label: 'Bottom',
    value: 'bottom'
  },
  {
    label: 'Top',
    value: 'top'
  },
  {
    label: 'Left',
    value: 'left'
  },
  {
    label: 'Right',
    value: 'right'
  }
]);
const activeIndex = ref(0);
const next = () => {
  window.electronAPI.onPageDown();
};
const prev = () => {
  window.electronAPI.onPageUp();
};
document.addEventListener('keydown', (event) => {
  if (event.key === 'ArrowRight') {
    imgSrc.value = '';
    next();
  }
  if (event.key === 'ArrowLeft') {
    imgSrc.value = '';
    prev();
  }
});
</script>

<template>
  <div class="card flex justify-content-center">
    <Image alt="Image" show="false">
      <!-- <template #indicatoricon>
        <i class="pi pi-search"></i>
      </template> -->
      <template #image>
        <img :src="imgSrc" style="max-width: 100vw; max-height: 99vh;">
      </template>
      <template #preview="slotProps">
        <img :src="imgSrc" alt="preview" :style="slotProps.style" @click="slotProps.onClick" />
      </template>
    </Image>
    <!-- <ProgressSpinner style="width: 50px; height: 50px" strokeWidth="8" fill="var(--surface-ground)"
            animationDuration=".5s" aria-label="Custom ProgressSpinner" /> -->
  </div>

  <!-- <Galleria v-model:activeIndex="activeIndex" :value="images" :responsiveOptions="responsiveOptions" :numVisible="10"
      :thumbnailsPosition="top" containerStyle="max-width: 640px" :showItemNavigators="true"
      :showItemNavigatorsOnHover="true" :showThumbnails="true">
      <template #item="slotProps">
        <img :src="slotProps.item.itemImageSrc" :alt="slotProps.item.alt" style="width: 100%; display: block" />
      </template>
      <template #thumbnail="slotProps">
        <div class="grid grid-nogutter justify-content-center">
          <img :src="slotProps.item.thumbnailImageSrc" :alt="slotProps.item.alt"
            style="width: 100%; display: block; height: 10%;max-height: 200px;" />
        </div>
      </template>
    </Galleria> -->
</template>

<style scoped></style>
