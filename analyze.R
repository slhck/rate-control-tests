library(tidyverse)
library(stringr)
library(magrittr)
library(RColorBrewer)

rm(list=ls())

# ================================================================================

frame_info = data.frame()
temp = Sys.glob("csv/*.csv")

for (i in 1:length(temp)) {
  filename = temp[[i]]
  data = read.csv(filename, header = TRUE, stringsAsFactors = FALSE)
  names(data) = c("frame", "pts", "size", "frame_type")
  data$basename = str_replace(filename, ".csv", "")
  data$basename %<>% str_replace("csv/", "")
  data$frame_index = seq_along(data$frame_type)
  data %<>% select(-frame)
  frame_info = bind_rows(frame_info, data)
}

frame_info %<>%
  separate(basename, into=c("input_file", "rate_mode", "param"), sep = "-")

frame_info$input_file %<>% as.factor
frame_info$rate_mode %<>% as.factor

# -------------------------------------------------------------------------------

bitrates_overview = read.csv("bitrates.csv")
# output0-2pass-1500K.mp4
d = bitrates_overview %>%
  select(filename, bitrate) %>%
  mutate(
    basename = str_replace(str_replace(filename, ".mp4", ""), "videos/", ""),
    bitrate = bitrate / 1000
  ) %>%
  separate(basename, into=c("input_file", "rate_mode", "param"), sep = "-") %>%
  select(-filename)

d$input_file %<>% as.factor
d$rate_mode %<>% as.factor

d = left_join(d, frame_info)

# -------------------------------------------------------------------------------

d.crf_vbv = d %>% filter(rate_mode == "crfVbv") %>%
  separate(param, into=c("param", "target_bitrate"), sep = "_") %>%
  mutate(target_bitrate = as.integer(str_replace(target_bitrate, "K", "")))

d.quality_modes = d %>% filter(rate_mode %in% c("crf", "qp"))

d.rate_modes = d %>% filter(rate_mode %in% c("2pass", "2passVbv", "abr", "abrVbv")) %>%
  mutate(target_bitrate = as.integer(str_replace(param, "K", ""))) %>%
  select(-param)

d.all = bind_rows(d.rate_modes, d.quality_modes, d.crf_vbv)

# ggplot(d.rate_modes, aes(as.factor(target_bitrate), bitrate, fill = rate_mode)) + 
#   geom_bar(stat = "identity", position = position_dodge()) +
#   facet_wrap(~input_file)

# ==========================================================================

input_file_mapping = c(
  BigBuckBunny0 = "BBB 1",
  BigBuckBunny120 = "BBB 2",
  BigBuckBunny240 = "BBB 3",
  TearsOfSteel10 = "ToS 1",
  TearsOfSteel120 = "ToS 2",
  TearsOfSteel240 = "ToS 3"
)

d.rate_modes %>%
  filter(target_bitrate %in% c(3000, 7500)) %>%
  ggplot(aes(x = frame_index, y = size, color = rate_mode)) +
  geom_smooth(method = "loess", se = FALSE) +
  scale_color_discrete(
    "Rate Control Mode",
    breaks = c("2pass", "2passVbv", "abr", "abrVbv"),
    labels = c("2-pass", "2-pass + VBV", "ABR", "ABR + VBV")
  ) +
  facet_grid(input_file~target_bitrate, labeller = labeller(
    input_file = input_file_mapping
  )) +
  xlab("Frame Index") +
  ylab("Frame Size") + 
  theme(legend.position = "bottom")
ggsave("rate_modes.png", width = 8, height = 10, dpi = 100)

d.quality_modes %>%
  filter(param %in% c("17", "23")) %>%
  ggplot(aes(x = frame_index, y = size, color = rate_mode)) +
  geom_smooth(method = "loess", se = FALSE) +
  scale_color_discrete(
    "Rate Control Mode",
    breaks = c("crf", "qp"),
    labels = c("CRF", "CQP")
  ) +
  facet_grid(input_file~param, labeller = labeller(
    input_file = input_file_mapping
  )) +
  xlab("Frame Index") +
  ylab("Frame Size") +
  theme(legend.position = "bottom")
ggsave("quality_modes.png", width = 8, height = 10, dpi = 100)

d.crf_vbv %>%
  filter(param %in% c("17", "23")) %>%
  #filter(target_bitrate %in% c(3000, 7500)) %>%
  ggplot(aes(x = frame_index, y = size, color = as.factor(target_bitrate))) +
  geom_smooth(method = "loess", se = FALSE) +
  scale_color_discrete("Target / VBV Maximum Bitrate") +
  facet_grid(input_file~param, labeller = labeller(
    input_file = input_file_mapping
  )) +
  xlab("Frame Index") +
  ylab("Frame Size") +
  theme(legend.position = "bottom")
ggsave("crf_vbv_modes.png", width = 8, height = 10, dpi = 100)